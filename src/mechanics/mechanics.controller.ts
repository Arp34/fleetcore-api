import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Auth } from '../common/decorators/auth.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { Role } from '../common/enums/role.enum.js';
import { CreateMechanicDto } from './dto/create-mechanic.dto.js';
import { QueryMechanicDto } from './dto/query-mechanic.dto.js';
import { UpdateMechanicDto } from './dto/update-mechanic.dto.js';
import { MechanicsService } from './mechanics.service.js';

@ApiTags('mechanics')
@Controller('mechanics')
export class MechanicsController {
  constructor(private readonly mechanicsService: MechanicsService) {}

  @Auth(Role.ADMIN)
  @Post()
  create(@Body() dto: CreateMechanicDto) {
    return this.mechanicsService.create(dto);
  }

  @Auth()
  @Get()
  findAll(@Query() query: QueryMechanicDto) {
    return this.mechanicsService.findAll(query);
  }

  // Technician's own mechanic profile, resolved from the JWT
  // Ficha de mecánico del propio técnico, se obtiene desde el JWT
  @Auth(Role.TECHNICIAN)
  @Get('me')
  findMe(@CurrentUser('sub') userId: string) {
    return this.mechanicsService.findByUserId(userId);
  }

  @Auth()
  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.mechanicsService.findOne(id);
  }

  @Auth(Role.ADMIN)
  @Patch(':id')
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateMechanicDto) {
    return this.mechanicsService.update(id, dto);
  }

  @Auth(Role.ADMIN)
  @Patch(':id/activate')
  activate(@Param('id', ParseUUIDPipe) id: string) {
    return this.mechanicsService.setActive(id, true);
  }

  @Auth(Role.ADMIN)
  @Patch(':id/deactivate')
  deactivate(@Param('id', ParseUUIDPipe) id: string) {
    return this.mechanicsService.setActive(id, false);
  }
}
