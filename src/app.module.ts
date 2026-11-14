import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { envSchema, type Env } from './config/env.schema.js';
import { type MiddlewareConsumer, type NestModule } from '@nestjs/common';
import { LoggerMiddleware } from './common/middleware/logger.middleware.js';

import { APP_GUARD } from '@nestjs/core';
import { AuthModule } from './auth/auth.module.js';
import { UsersModule } from './users/users.module.js';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard.js';
import { RolesGuard } from './common/guards/roles.guard.js';
import { VehiclesModule } from './vehicles/vehicles.module.js';
import { MechanicsModule } from './mechanics/mechanics.module.js';
import { WorkshopsModule } from './workshops/workshops.module.js';
import { MaintenancesModule } from './maintenances/maintenances.module.js';
import { IntegrationsModule } from './integrations/integrations.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: process.env.NODE_ENV === 'test' ? '.env.test' : '.env',
      validate: (config) => envSchema.parse(config),
    }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) => ({
        type: 'postgres',
        // Cloud (Neon): one URL + SSL. Local Docker: separate DB_* variables, no SSL
        // Nube (Neon): una URL + SSL. Docker local: variables DB_* separadas, sin SSL
        ...(config.get('DATABASE_URL', { infer: true })
          ? { url: config.get('DATABASE_URL', { infer: true }), ssl: true }
          : {
              host: config.get('DB_HOST', { infer: true }),
              port: config.get('DB_PORT', { infer: true }),
              username: config.get('DB_USERNAME', { infer: true }),
              password: config.get('DB_PASSWORD', { infer: true }),
              database: config.get('DB_NAME', { infer: true }),
            }),
        autoLoadEntities: true,
        synchronize: config.get('DB_SYNC', { infer: true }),
        dropSchema: config.get('NODE_ENV', { infer: true }) === 'test',
      }),
    }),
    UsersModule,
    AuthModule,
    VehiclesModule,
    MechanicsModule,
    WorkshopsModule,
    MaintenancesModule,
    IntegrationsModule,
  ],
  controllers: [],
  providers: [
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})

export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerMiddleware).forRoutes('{*splat}');
  }
}