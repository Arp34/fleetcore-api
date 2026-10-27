import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Auth } from '../common/decorators/auth.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { PaginationDto } from '../common/dto/pagination.dto.js';
import { Role } from '../common/enums/role.enum.js';
import type { JwtPayload } from '../common/interfaces/jwt-payload.interface.js';
import { CreateMaintenanceDto } from './dto/create-maintenance.dto.js';
import { QueryMaintenanceDto } from './dto/query-maintenance.dto.js';
import { UpdateMaintenanceStatusDto } from './dto/update-maintenance-status.dto.js';
import { MaintenancesService } from './maintenances.service.js';

@ApiTags('maintenances')
@Controller('maintenances')
export class MaintenancesController {
  constructor(private readonly maintenancesService: MaintenancesService) {}

  @Auth(Role.ADMIN)
  @Post()
  create(@Body() dto: CreateMaintenanceDto, @CurrentUser('sub') userId: string) {
    return this.maintenancesService.create(dto, userId);
  }

  @Auth(Role.ADMIN)
  @Get()
  findAll(@Query() query: QueryMaintenanceDto) {
    return this.maintenancesService.findAll(query);
  }

  // Fixed routes go before ':id', otherwise "active" or "my" would be read as an id
  // Las rutas fijas van antes de ':id', si no "active" o "my" se leerían como un id
  @Auth(Role.ADMIN)
  @Get('active')
  findActive() {
    return this.maintenancesService.findActive();
  }

  @Auth(Role.ADMIN)
  @Get('audit')
  findAuditLog(@Query() query: PaginationDto) {
    return this.maintenancesService.findAuditLog(query);
  }

  @Auth(Role.TECHNICIAN)
  @Get('my')
  findMine(@CurrentUser('sub') userId: string) {
    return this.maintenancesService.findMine(userId);
  }

  @Auth(Role.ADMIN)
  @Get('vehicle/:vehicleId')
  findByVehicle(@Param('vehicleId', ParseUUIDPipe) vehicleId: string) {
    return this.maintenancesService.findByVehicle(vehicleId);
  }

  @Auth(Role.ADMIN)
  @Get('vehicle/:vehicleId/history')
  getHistory(@Param('vehicleId', ParseUUIDPipe) vehicleId: string) {
    return this.maintenancesService.getHistoryById(vehicleId);
  }

  @Auth(Role.ADMIN)
  @Get('mechanic/:mechanicId')
  findByMechanic(@Param('mechanicId', ParseUUIDPipe) mechanicId: string) {
    return this.maintenancesService.findByMechanic(mechanicId);
  }

  @Auth(Role.ADMIN)
  @Get(':id/audit')
  findAuditByMaintenance(@Param('id', ParseUUIDPipe) id: string) {
    return this.maintenancesService.findAuditByMaintenance(id);
  }

  @Auth(Role.ADMIN, Role.TECHNICIAN)
  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: JwtPayload) {
    return this.maintenancesService.findOne(id, user);
  }

  @Auth(Role.ADMIN, Role.TECHNICIAN)
  @Patch(':id/status')
  changeStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateMaintenanceStatusDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.maintenancesService.changeStatus(id, dto, user);
  }
}
