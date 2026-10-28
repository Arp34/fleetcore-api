import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDate, IsEnum, IsInt, IsNotEmpty, IsOptional, IsString, IsUUID, Max, MaxLength, Min } from 'class-validator';
import { MaintenanceType } from '../enums/maintenance-type.enum.js';

export class CreateMaintenanceDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  vehicleId: string;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  mechanicId: string;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  workshopId: string;

  @ApiProperty({ enum: MaintenanceType, example: MaintenanceType.PREVENTIVE })
  @IsEnum(MaintenanceType)
  type: MaintenanceType;

  @ApiProperty({ example: 'Cambio de aceite y filtros' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  description: string;

  @ApiProperty({ example: 46000, description: 'Kilometraje del vehículo al ingresar' })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  mileage: number;

  // ISO 8601 string ("2026-11-03T07:30:00-05:00") converted to Date before validating
  // Texto ISO 8601 ("2026-11-03T07:30:00-05:00") convertido a Date antes de validar
  @ApiProperty({ example: '2026-11-03T07:30:00-05:00' })
  @Type(() => Date)
  @IsDate({ message: 'scheduledAt debe ser una fecha ISO válida' })
  scheduledAt: Date;

  // Optional: if not sent, the service uses 60 minutes to calculate the end time
  // Opcional: si no se envía, el servicio usa 60 minutos para calcular la hora de fin
  @ApiPropertyOptional({ example: 90, default: 60, description: 'Duración estimada en minutos (define la hora de fin)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(15)
  @Max(720)
  durationMinutes?: number;
}
