import { Column, Entity, Index, JoinColumn, ManyToOne, type Relation } from 'typeorm';
import { AppBaseEntity } from '../../common/entities/base.entity.js';
import type { User } from '../../users/entities/user.entity.js';
import { MaintenanceStatus } from '../enums/maintenance-status.enum.js';
import type { Maintenance } from './maintenance.entity.js';

// Audit trail: one row per status change (who, from, to, when). Rows are only inserted, never edited
// Auditoría: una fila por cada cambio de estado (quién, desde, hacia, cuándo). Solo se insertan, nunca se editan
@Entity('maintenance_status_logs')
@Index(['maintenanceId'])
export class MaintenanceStatusLog extends AppBaseEntity {
  @Column({ name: 'maintenance_id', type: 'uuid' })
  maintenanceId: string;

  // null = the maintenance was just created
  // null = el mantenimiento se acaba de crear
  @Column({ name: 'from_status', type: 'enum', enum: MaintenanceStatus, nullable: true })
  fromStatus: MaintenanceStatus | null;

  @Column({ name: 'to_status', type: 'enum', enum: MaintenanceStatus })
  toStatus: MaintenanceStatus;

  @Column({ name: 'changed_by_id', type: 'uuid', nullable: true })
  changedById: string | null;

  @ManyToOne('Maintenance', { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'maintenance_id' })
  maintenance: Relation<Maintenance>;

  @ManyToOne('User', { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'changed_by_id' })
  changedBy: Relation<User> | null;
}
