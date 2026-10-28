import {
  BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, In, LessThan, MoreThan, Not, Repository, type FindOptionsWhere } from 'typeorm';
import { Role } from '../common/enums/role.enum.js';
import type { JwtPayload } from '../common/interfaces/jwt-payload.interface.js';
import { Mechanic } from '../mechanics/entities/mechanic.entity.js';
import { MechanicsService } from '../mechanics/mechanics.service.js';
import { Vehicle } from '../vehicles/entities/vehicle.entity.js';
import { VehicleStatus } from '../vehicles/enums/vehicle-status.enum.js';
import { VehiclesService } from '../vehicles/vehicles.service.js';
import { Workshop } from '../workshops/entities/workshop.entity.js';
import type { PaginationDto } from '../common/dto/pagination.dto.js';
import type { CreateMaintenanceDto } from './dto/create-maintenance.dto.js';
import type { QueryMaintenanceDto } from './dto/query-maintenance.dto.js';
import type { UpdateMaintenanceStatusDto } from './dto/update-maintenance-status.dto.js';
import { MaintenanceStatusLog } from './entities/maintenance-status-log.entity.js';
import { Maintenance } from './entities/maintenance.entity.js';
import { MaintenanceStatus } from './enums/maintenance-status.enum.js';
import { ACTIVE_STATUSES, assertClosingData, assertValidTransition } from './maintenance-status.rules.js';

const FULL_RELATIONS = { vehicle: true, mechanic: true, workshop: true };
const DEFAULT_DURATION_MINUTES = 60;

@Injectable()
export class MaintenancesService {
  constructor(
    @InjectRepository(Maintenance) private readonly maintenancesRepo: Repository<Maintenance>,
    @InjectRepository(MaintenanceStatusLog) private readonly logsRepo: Repository<MaintenanceStatusLog>,
    private readonly dataSource: DataSource,
    private readonly vehiclesService: VehiclesService,
    private readonly mechanicsService: MechanicsService,
  ) {}

  // Transaction: every check and the insert run together; if any step fails nothing is saved
  // Transacción: todas las validaciones y el insert van juntos; si algo falla no se guarda nada
  async create(dto: CreateMaintenanceDto, userId: string) {
    const saved = await this.dataSource.transaction(async (manager) => {
      // pessimistic_write = SELECT ... FOR UPDATE: two simultaneous requests for the same vehicle/mechanic wait in line
      // pessimistic_write = SELECT ... FOR UPDATE: dos peticiones simultáneas al mismo vehículo/mecánico hacen fila
      const vehicle = await manager.findOne(Vehicle, {
        where: { id: dto.vehicleId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!vehicle) throw new NotFoundException(`Vehículo ${dto.vehicleId} no encontrado`);
      if (vehicle.status === VehicleStatus.INACTIVE) {
        throw new ConflictException(`El vehículo ${vehicle.plate} está inactivo y no puede recibir mantenimientos`);
      }

      const mechanic = await manager.findOne(Mechanic, {
        where: { id: dto.mechanicId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!mechanic) throw new NotFoundException(`Mecánico ${dto.mechanicId} no encontrado`);
      if (!mechanic.isActive) throw new ConflictException(`El mecánico ${mechanic.name} está inactivo`);

      const workshop = await manager.findOneBy(Workshop, { id: dto.workshopId });
      if (!workshop) throw new NotFoundException(`Taller ${dto.workshopId} no encontrado`);
      if (!workshop.isActive) throw new ConflictException(`El taller ${workshop.name} está inactivo`);

      if (dto.mileage < vehicle.mileage) {
        throw new BadRequestException(
          `El kilometraje (${dto.mileage}) no puede ser inferior al actual del vehículo (${vehicle.mileage})`,
        );
      }

      const vehicleBusy = await manager.exists(Maintenance, {
        where: { vehicleId: vehicle.id, status: In(ACTIVE_STATUSES) },
      });
      if (vehicleBusy) {
        throw new ConflictException(`El vehículo ${vehicle.plate} ya tiene un mantenimiento activo`);
      }

      // Overlap rule: two ranges cross when existing.start < new.end AND existing.end > new.start.
      // Strict "<" and ">" allow back-to-back slots (7:30-9:00 and 9:00-10:00 do NOT cross)
      // Regla de cruce: dos rangos se cruzan si inicioExistente < finNuevo Y finExistente > inicioNuevo.
      // Al ser "<" y ">" estrictos se permiten turnos seguidos (7:30-9:00 y 9:00-10:00 NO se cruzan)
      const durationMinutes = dto.durationMinutes ?? DEFAULT_DURATION_MINUTES;
      const start = dto.scheduledAt;
      const end = new Date(start.getTime() + durationMinutes * 60_000);
      const overlap = await manager.findOne(Maintenance, {
        where: {
          mechanicId: mechanic.id,
          status: In(ACTIVE_STATUSES),
          scheduledAt: LessThan(end),
          estimatedEndAt: MoreThan(start),
        },
      });
      if (overlap) {
        throw new ConflictException(
          `El mecánico ${mechanic.name} ya tiene un mantenimiento entre ` +
            `${overlap.scheduledAt.toISOString()} y ${overlap.estimatedEndAt.toISOString()}`,
        );
      }

      // Initial status is always SCHEDULED (column default); the client cannot choose it
      // El estado inicial siempre es SCHEDULED (default de la columna); el cliente no lo elige
      const maintenance = await manager.save(
        manager.create(Maintenance, { ...dto, durationMinutes, estimatedEndAt: end }),
      );
      // Audit row saved in the same transaction: if the insert fails, no orphan log remains
      // Fila de auditoría guardada en la misma transacción: si el insert falla, no queda un log huérfano
      await manager.save(MaintenanceStatusLog, {
        maintenanceId: maintenance.id, fromStatus: null, toStatus: maintenance.status, changedById: userId,
      });
      return maintenance;
    });
    return this.maintenancesRepo.findOne({ where: { id: saved.id }, relations: FULL_RELATIONS });
  }

  async changeStatus(id: string, dto: UpdateMaintenanceStatusDto, user: JwtPayload) {
    await this.dataSource.transaction(async (manager) => {
      const maintenance = await manager.findOne(Maintenance, {
        where: { id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!maintenance) throw new NotFoundException(`Mantenimiento ${id} no encontrado`);

      const mechanic = await manager.findOneByOrFail(Mechanic, { id: maintenance.mechanicId });
      this.assertCanAccess(mechanic, user);
      assertValidTransition(maintenance.status, dto.status);

      const vehicle = await manager.findOneOrFail(Vehicle, {
        where: { id: maintenance.vehicleId },
        lock: { mode: 'pessimistic_write' },
      });

      if (dto.status === MaintenanceStatus.IN_PROGRESS) {
        // Re-check: vehicle, mechanic or workshop may have been deactivated after scheduling
        // Se revisa de nuevo: el vehículo, mecánico o taller pudo inactivarse después de programar
        if (vehicle.status === VehicleStatus.INACTIVE) {
          throw new ConflictException(`El vehículo ${vehicle.plate} está inactivo`);
        }
        if (!mechanic.isActive) throw new ConflictException(`El mecánico ${mechanic.name} está inactivo`);
        const workshop = await manager.findOneByOrFail(Workshop, { id: maintenance.workshopId });
        if (!workshop.isActive) throw new ConflictException(`El taller ${workshop.name} está inactivo`);
        // A technician can only work on one maintenance at a time
        // Un técnico solo puede estar trabajando en un mantenimiento a la vez
        const mechanicBusy = await manager.exists(Maintenance, {
          where: { mechanicId: mechanic.id, status: MaintenanceStatus.IN_PROGRESS, id: Not(maintenance.id) },
        });
        if (mechanicBusy) {
          throw new ConflictException(`El mecánico ${mechanic.name} ya tiene otro mantenimiento en proceso`);
        }
        maintenance.startedAt = new Date();
        vehicle.status = VehicleStatus.IN_MAINTENANCE;
      }

      if (dto.status === MaintenanceStatus.COMPLETED) {
        assertClosingData(dto);
        const finishedAt = dto.finishedAt as Date;
        const finalMileage = dto.finalMileage as number;
        if (finalMileage < maintenance.mileage) {
          throw new BadRequestException(
            `El kilometraje final (${finalMileage}) no puede ser menor al de ingreso (${maintenance.mileage})`,
          );
        }
        if (maintenance.startedAt && finishedAt < maintenance.startedAt) {
          throw new BadRequestException('La fecha de finalización no puede ser anterior al inicio');
        }
        maintenance.workPerformed = dto.workPerformed as string;
        maintenance.finalCost = dto.finalCost as number;
        maintenance.finishedAt = finishedAt;
        maintenance.finalMileage = finalMileage;
        vehicle.status = VehicleStatus.AVAILABLE;
        vehicle.mileage = Math.max(vehicle.mileage, finalMileage);
      }

      // Cancelling a job that already started frees the vehicle again
      // Cancelar un trabajo que ya había empezado libera de nuevo el vehículo
      if (dto.status === MaintenanceStatus.CANCELLED && maintenance.status === MaintenanceStatus.IN_PROGRESS) {
        vehicle.status = VehicleStatus.AVAILABLE;
      }

      await manager.save(MaintenanceStatusLog, {
        maintenanceId: maintenance.id, fromStatus: maintenance.status, toStatus: dto.status, changedById: user.sub,
      });
      maintenance.status = dto.status;
      await manager.save(maintenance);
      await manager.save(vehicle);
    });
    return this.maintenancesRepo.findOne({ where: { id }, relations: FULL_RELATIONS });
  }

  async findAll({ page, limit, status, vehicleId, mechanicId }: QueryMaintenanceDto) {
    const where: FindOptionsWhere<Maintenance> = {};
    if (status) where.status = status;
    if (vehicleId) where.vehicleId = vehicleId;
    if (mechanicId) where.mechanicId = mechanicId;

    const [items, total] = await this.maintenancesRepo.findAndCount({
      where,
      relations: FULL_RELATIONS,
      order: { scheduledAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { items, meta: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  findActive() {
    return this.maintenancesRepo.find({
      where: { status: In(ACTIVE_STATUSES) },
      relations: FULL_RELATIONS,
      order: { scheduledAt: 'ASC' },
    });
  }

  async findByVehicle(vehicleId: string) {
    await this.vehiclesService.findOne(vehicleId);
    return this.maintenancesRepo.find({
      where: { vehicleId },
      relations: { mechanic: true, workshop: true },
      order: { scheduledAt: 'DESC' },
    });
  }

  async findByMechanic(mechanicId: string) {
    await this.mechanicsService.findOne(mechanicId);
    return this.maintenancesRepo.find({
      where: { mechanicId },
      relations: { vehicle: true, workshop: true },
      order: { scheduledAt: 'DESC' },
    });
  }

  // The technician never sends a mechanicId: it is taken from the JWT, so they can't see others' work
  // El técnico nunca envía un mechanicId: se toma del JWT, así no puede ver trabajos ajenos
  async findMine(userId: string) {
    const mechanic = await this.mechanicsService.findByUserId(userId);
    return this.findByMechanic(mechanic.id);
  }

  async findOne(id: string, user: JwtPayload) {
    const maintenance = await this.maintenancesRepo.findOne({ where: { id }, relations: FULL_RELATIONS });
    if (!maintenance) throw new NotFoundException(`Mantenimiento ${id} no encontrado`);
    this.assertCanAccess(maintenance.mechanic, user);
    return maintenance;
  }

  async findAuditLog({ page, limit }: PaginationDto) {
    const [items, total] = await this.logsRepo.findAndCount({
      relations: { maintenance: { vehicle: true }, changedBy: true },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return {
      items: items.map((log) => this.toAuditItem(log)),
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findAuditByMaintenance(id: string) {
    const exists = await this.maintenancesRepo.exists({ where: { id } });
    if (!exists) throw new NotFoundException(`Mantenimiento ${id} no encontrado`);
    const logs = await this.logsRepo.find({
      where: { maintenanceId: id },
      relations: { maintenance: { vehicle: true }, changedBy: true },
      order: { createdAt: 'ASC' },
    });
    return logs.map((log) => this.toAuditItem(log));
  }

  private toAuditItem(log: MaintenanceStatusLog) {
    return {
      id: log.id,
      maintenanceId: log.maintenanceId,
      vehiclePlate: log.maintenance.vehicle.plate,
      fromStatus: log.fromStatus,
      toStatus: log.toStatus,
      changedBy: log.changedBy
        ? { id: log.changedBy.id, name: log.changedBy.name, role: log.changedBy.role }
        : null,
      changedAt: log.createdAt,
    };
  }

  async getHistoryById(vehicleId: string) {
    return this.buildHistory(await this.vehiclesService.findOne(vehicleId));
  }

  async getHistoryByPlate(plate: string) {
    return this.buildHistory(await this.vehiclesService.findByPlate(plate));
  }

  // History = only COMPLETED maintenances, oldest first, with a reduced shape for reports/integrations
  // Historial = solo mantenimientos COMPLETED, del más antiguo al más reciente, con forma reducida para reportes
  private async buildHistory(vehicle: Vehicle) {
    const maintenances = await this.maintenancesRepo.find({
      where: { vehicleId: vehicle.id, status: MaintenanceStatus.COMPLETED },
      relations: { mechanic: true, workshop: true },
      order: { finishedAt: 'ASC' },
    });
    return {
      vehicle: {
        id: vehicle.id,
        plate: vehicle.plate,
        brand: vehicle.brand,
        model: vehicle.model,
        available: vehicle.status === VehicleStatus.AVAILABLE,
      },
      maintenances: maintenances.map((m) => ({
        id: m.id,
        type: m.type,
        status: m.status,
        description: m.description,
        workPerformed: m.workPerformed,
        mileage: m.finalMileage,
        cost: m.finalCost,
        finishedAt: m.finishedAt,
        mechanic: { id: m.mechanic.id, name: m.mechanic.name },
        workshop: { id: m.workshop.id, name: m.workshop.name },
      })),
    };
  }

  // ADMIN sees everything; a TECHNICIAN only the maintenances of the mechanic linked to their user
  // ADMIN ve todo; un TECHNICIAN solo los mantenimientos del mecánico vinculado a su usuario
  private assertCanAccess(mechanic: Mechanic, user: JwtPayload) {
    if (user.role !== Role.ADMIN && mechanic.userId !== user.sub) {
      throw new ForbiddenException('Este mantenimiento no está asignado a ti');
    }
  }
}
