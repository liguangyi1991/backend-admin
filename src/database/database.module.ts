import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'mysql',
        host: configService.get<string>('database.host'),
        port: configService.get<number>('database.port'),
        username: configService.get<string>('database.username'),
        password: configService.get<string>('database.password'),
        database: configService.get<string>('database.name'),
        entities: [__dirname + '/../**/*.entity{.ts,.js}'],
        synchronize:
          configService.get<string>('app.environment') === 'development',
        logging: configService.get<string>('app.environment') === 'development',
        ssl:
          configService.get<string>('app.environment') === 'production'
            ? {
                rejectUnauthorized: false,
              }
            : false,
      }),
      inject: [ConfigService],
    }),
  ],
})
export class DatabaseModule {}
