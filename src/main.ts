import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);
  
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));
  
  const port = configService.get<number>('port') || 3000;
  const appName = configService.get<string>('app.name') || 'Backend Admin';
  const environment = configService.get<string>('app.environment') || 'development';
  
  await app.listen(port);
  
  console.log(`🚀 ${appName} is running on port ${port} in ${environment} mode`);
}
bootstrap();
