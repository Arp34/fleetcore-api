import { Column, Entity, Index, JoinColumn, ManyToOne, type Relation } from 'typeorm';
import { AppBaseEntity } from '../../common/entities/base.entity.js';
import type { Mechanic } from '../../mechanics/entities/mechanic.entity.js';
import type { Vehicle } from '../../vehicles/entities/vehicle.entity.js';
import type { Workshop } from '../../workshops/entities/workshop.entity.js';
import { MaintenanceStatus } from '../enums/maintenance-status.enum.js';
import { MaintenanceType } from '../enums/maintenance-type.enum.js';

// Postgres returns numeric as string (to avoid losing decimals); convert it back to number
// Postgres devuelve numeric como texto (para no perder decimales); se convierte de nuevo a número
const numericToNumber = {
  to: (value: number | null) => value,
  from: (value: string | null) => (value === null ? null : Number(value)),
};

@Entity('maintenances')
@Index(['mechanicId', 'status'])
export class Maintenance extends AppBaseEntity {
  @Column({ type: 'enum', enum: MaintenanceType })
  type: MaintenanceType;

  @Column({ type: 'text' })
  description: string;

  @Column({ type: 'int' })
  mileage: number;

  @Column({ name: 'scheduled_at', type: 'timestamptz' })
  scheduledAt: Date;

  @Column({ name: 'duration_minutes', type: 'int' })
  durationMinutes: number;

  // Stored (not calculated on each query) so the schedule-overlap check is a simple WHERE
  // Se guarda (no se calcula en cada consulta) para que el cruce de horarios sea un WHERE simple
  @Column({ name: 'estimated_end_at', type: 'timestamptz' })
  estimatedEndAt: Date;

  @Column({ type: 'enum', enum: MaintenanceStatus, default: MaintenanceStatus.SCHEDULED })
  status: MaintenanceStatus;

  @Column({ name: 'started_at', type: 'timestamptz', nullable: true })
  startedAt: Date | null;

  // Closing data: null until the maintenance is COMPLETED
  // Datos de cierre: null hasta que el mantenimiento pase a COMPLETED
  @Column({ name: 'work_performed', type: 'text', nullable: true })
  workPerformed: string | null;

  @Column({ name: 'final_cost', type: 'numeric', precision: 12, scale: 2, nullable: true, transformer: numericToNumber })
  finalCost: number | null;

  @Column({ name: 'finished_at', type: 'timestamptz', nullable: true })
  finishedAt: Date | null;

  @Column({ name: 'final_mileage', type: 'int', nullable: true })
  finalMileage: number | null;

  @Column({ name: 'vehicle_id', type: 'uuid' })
  vehicleId: string;

  @Column({ name: 'mechanic_id', type: 'uuid' })
  mechanicId: string;

  @Column({ name: 'workshop_id', type: 'uuid' })
  workshopId: string;

  // ManyToOne: many maintenances belong to one vehicle. RESTRICT blocks deleting a vehicle that has history
  // ManyToOne: muchos mantenimientos pertenecen a un vehículo. RESTRICT impide borrar un vehículo con historial
  @ManyToOne('Vehicle', { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'vehicle_id' })
  vehicle: Relation<Vehicle>;

  @ManyToOne('Mechanic', { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'mechanic_id' })
  mechanic: Relation<Mechanic>;

  @ManyToOne('Workshop', { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'workshop_id' })
  workshop: Relation<Workshop>;
}
