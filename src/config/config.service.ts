import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AppConfigService {
  constructor(private configService: ConfigService) {}

  get port(): number {
    return this.configService.get<number>('port') || 3000;
  }

  get appName(): string {
    return this.configService.get<string>('app.name') || 'Backend Admin';
  }

  get appVersion(): string {
    return this.configService.get<string>('app.version') || '1.0.0';
  }

  get environment(): string {
    return this.configService.get<string>('app.environment') || 'development';
  }

  get jwtSecret(): string {
    return this.configService.get<string>('jwt.secret') || 'default-secret';
  }

  get jwtExpiresIn(): string {
    return this.configService.get<string>('jwt.expiresIn') || '24h';
  }

  get databaseConfig() {
    return {
      host: this.configService.get<string>('database.host'),
      port: this.configService.get<number>('database.port'),
      username: this.configService.get<string>('database.username'),
      password: this.configService.get<string>('database.password'),
      database: this.configService.get<string>('database.name'),
    };
  }

  get redisConfig() {
    return {
      host: this.configService.get<string>('redis.host'),
      port: this.configService.get<number>('redis.port'),
      password: this.configService.get<string>('redis.password'),
    };
  }

  get logLevel(): string {
    return this.configService.get<string>('log.level') || 'info';
  }

  get isDevelopment(): boolean {
    return this.environment === 'development';
  }

  get isProduction(): boolean {
    return this.environment === 'production';
  }

  get isTest(): boolean {
    return this.environment === 'test';
  }
}