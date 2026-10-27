import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { hash } from 'bcryptjs';
import { DataSource, type EntityManager, type EntityTarget, type FindOptionsWhere, type ObjectLiteral } from 'typeorm';
import { AppModule } from '../app.module.js';
import { Role } from '../common/enums/role.enum.js';
import { MaintenanceStatusLog } from '../maintenances/entities/maintenance-status-log.entity.js';
import { Maintenance } from '../maintenances/entities/maintenance.entity.js';
import { MaintenanceStatus } from '../maintenances/enums/maintenance-status.enum.js';
import { MaintenanceType } from '../maintenances/enums/maintenance-type.enum.js';
import { Mechanic } from '../mechanics/entities/mechanic.entity.js';
import { User } from '../users/entities/user.entity.js';
import { Vehicle } from '../vehicles/entities/vehicle.entity.js';
import { VehicleStatus } from '../vehicles/enums/vehicle-status.enum.js';
import { Workshop } from '../workshops/entities/workshop.entity.js';

const logger = new Logger('Seed');
let created = 0;

// Idempotent: look the record up by a natural key (email, plate, name) and insert it only if missing.
// Running the seed twice therefore never duplicates data
// Idempotente: busca el registro por una llave natural (email, placa, nombre) y lo inserta solo si no existe.
// Por eso ejecutar el seed dos veces nunca duplica datos
async function findOrCreate<T extends ObjectLiteral>(
  manager: EntityManager,
  entity: EntityTarget<T>,
  where: FindOptionsWhere<T>,
  data: Partial<T>,
): Promise<T> {
  const existing = await manager.findOneBy(entity, where);
  if (existing) return existing;
  created++;
  return manager.save(entity, manager.create(entity, { ...where, ...data } as T));
}

// Writes the audit trail of a seeded maintenance (only if it has none yet, to stay idempotent)
// Escribe la auditoría de un mantenimiento del seed (solo si aún no tiene, para seguir siendo idempotente)
async function seedStatusLogs(
  manager: EntityManager,
  maintenance: Maintenance,
  changedById: string,
  steps: { status: MaintenanceStatus; at: Date }[],
) {
  if (await manager.exists(MaintenanceStatusLog, { where: { maintenanceId: maintenance.id } })) return;
  let fromStatus: MaintenanceStatus | null = null;
  for (const step of steps) {
    created++;
    await manager.save(MaintenanceStatusLog, {
      maintenanceId: maintenance.id, fromStatus, toStatus: step.status, changedById, createdAt: step.at,
    });
    fromStatus = step.status;
  }
}

async function seed(manager: EntityManager) {
  // Users
  const userData = [
    { name: 'Administrador FleetCore', email: 'admin@fleetcore.com', password: 'Admin12345', role: Role.ADMIN },
    { name: 'Carlos Pérez', email: 'carlos.perez@fleetcore.com', password: 'Tecnico123', role: Role.TECHNICIAN },
    { name: 'Laura Gómez', email: 'laura.gomez@fleetcore.com', password: 'Tecnico123', role: Role.TECHNICIAN },
  ];
  const users: User[] = [];
  for (const { password, ...data } of userData) {
    users.push(
      await findOrCreate(manager, User, { email: data.email }, { ...data, password: await hash(password, 10) }),
    );
  }
  const [adminUser, carlosUser, lauraUser] = users;

  // Mechanics: 2 active linked to the technicians, 1 inactive
  const carlos = await findOrCreate(manager, Mechanic, { email: 'carlos.perez@fleetcore.com' }, {
    name: 'Carlos Pérez', specialty: 'Motor y transmisión', isActive: true, userId: carlosUser.id,
  });
  const laura = await findOrCreate(manager, Mechanic, { email: 'laura.gomez@fleetcore.com' }, {
    name: 'Laura Gómez', specialty: 'Frenos y suspensión', isActive: true, userId: lauraUser.id,
  });
  await findOrCreate(manager, Mechanic, { email: 'pedro.ruiz@fleetcore.com' }, {
    name: 'Pedro Ruiz', specialty: 'Sistema eléctrico', isActive: false, userId: null,
  });

  // Workshops: 1 active, 1 inactive
  const centro = await findOrCreate(manager, Workshop, { name: 'Taller Centro' }, {
    address: 'Calle 50 # 45-20, Medellín', isActive: true,
  });
  const norte = await findOrCreate(manager, Workshop, { name: 'Taller Norte' }, {
    address: 'Carrera 65 # 98-10, Medellín', isActive: false,
  });

  // Vehicles: 2 AVAILABLE, 1 IN_MAINTENANCE, 1 INACTIVE
  const abc = await findOrCreate(manager, Vehicle, { plate: 'ABC123' }, {
    brand: 'Chevrolet', model: 'NPR', year: 2020, mileage: 52300, status: VehicleStatus.AVAILABLE,
  });
  const def = await findOrCreate(manager, Vehicle, { plate: 'DEF456' }, {
    brand: 'Renault', model: 'Master', year: 2022, mileage: 30500, status: VehicleStatus.AVAILABLE,
  });
  const ghi = await findOrCreate(manager, Vehicle, { plate: 'GHI789' }, {
    brand: 'Hino', model: 'Dutro', year: 2019, mileage: 80000, status: VehicleStatus.IN_MAINTENANCE,
  });
  await findOrCreate(manager, Vehicle, { plate: 'JKL012' }, {
    brand: 'Foton', model: 'Aumark', year: 2015, mileage: 120000, status: VehicleStatus.INACTIVE,
  });

  // Maintenances: 2 COMPLETED (history of ABC123), 1 IN_PROGRESS (GHI789), 1 SCHEDULED (DEF456)
  const oilChange = await findOrCreate(manager, Maintenance, { vehicleId: abc.id, description: 'Cambio de aceite y filtros' }, {
    type: MaintenanceType.PREVENTIVE, mileage: 45000, status: MaintenanceStatus.COMPLETED,
    scheduledAt: new Date('2026-09-15T13:00:00Z'), durationMinutes: 180,
    estimatedEndAt: new Date('2026-09-15T16:00:00Z'), startedAt: new Date('2026-09-15T13:05:00Z'),
    workPerformed: 'Cambio de aceite 15W40, filtro de aceite y filtro de aire',
    finalCost: 350000, finishedAt: new Date('2026-09-15T16:30:00Z'), finalMileage: 45000,
    mechanicId: carlos.id, workshopId: norte.id,
  });
  const brakes = await findOrCreate(manager, Maintenance, { vehicleId: abc.id, description: 'Reemplazo de pastillas de freno' }, {
    type: MaintenanceType.CORRECTIVE, mileage: 52300, status: MaintenanceStatus.COMPLETED,
    scheduledAt: new Date('2026-10-10T12:00:00Z'), durationMinutes: 120,
    estimatedEndAt: new Date('2026-10-10T14:00:00Z'), startedAt: new Date('2026-10-10T12:10:00Z'),
    workPerformed: 'Reemplazo de pastillas delanteras y rectificación de discos',
    finalCost: 480000, finishedAt: new Date('2026-10-10T14:00:00Z'), finalMileage: 52300,
    mechanicId: laura.id, workshopId: centro.id,
  });
  const clutch = await findOrCreate(manager, Maintenance, { vehicleId: ghi.id, description: 'Falla en el sistema de embrague' }, {
    type: MaintenanceType.CORRECTIVE, mileage: 80000, status: MaintenanceStatus.IN_PROGRESS,
    scheduledAt: new Date('2026-10-27T12:30:00Z'), durationMinutes: 240,
    estimatedEndAt: new Date('2026-10-27T16:30:00Z'), startedAt: new Date('2026-10-27T12:40:00Z'),
    mechanicId: laura.id, workshopId: centro.id,
  });
  const review = await findOrCreate(manager, Maintenance, { vehicleId: def.id, description: 'Revisión de los 30.000 km' }, {
    type: MaintenanceType.PREVENTIVE, mileage: 30500, status: MaintenanceStatus.SCHEDULED,
    scheduledAt: new Date('2026-12-01T12:30:00Z'), durationMinutes: 90,
    estimatedEndAt: new Date('2026-12-01T14:00:00Z'),
    mechanicId: carlos.id, workshopId: centro.id,
  });

  // Audit trail (who changed each status and when)
  const { SCHEDULED, IN_PROGRESS, COMPLETED } = MaintenanceStatus;
  await seedStatusLogs(manager, oilChange, adminUser.id, [
    { status: SCHEDULED, at: new Date('2026-09-10T15:00:00Z') },
    { status: IN_PROGRESS, at: new Date('2026-09-15T13:05:00Z') },
    { status: COMPLETED, at: new Date('2026-09-15T16:30:00Z') },
  ]);
  await seedStatusLogs(manager, brakes, adminUser.id, [
    { status: SCHEDULED, at: new Date('2026-10-05T14:00:00Z') },
    { status: IN_PROGRESS, at: new Date('2026-10-10T12:10:00Z') },
    { status: COMPLETED, at: new Date('2026-10-10T14:00:00Z') },
  ]);
  await seedStatusLogs(manager, clutch, adminUser.id, [
    { status: SCHEDULED, at: new Date('2026-10-26T20:00:00Z') },
    { status: IN_PROGRESS, at: new Date('2026-10-27T12:40:00Z') },
  ]);
  await seedStatusLogs(manager, review, adminUser.id, [{ status: SCHEDULED, at: new Date('2026-10-27T15:00:00Z') }]);
}

async function run() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error', 'warn', 'log'] });
  try {
    // Whole seed in one transaction: if something fails halfway, the DB is left as it was
    // Todo el seed en una transacción: si algo falla a mitad, la BD queda como estaba
    await app.get(DataSource).transaction(seed);
    logger.log(created ? `Seed completado: ${created} registros creados` : 'Seed sin cambios: los datos ya existían');
  } finally {
    await app.close();
  }
}

await run();
