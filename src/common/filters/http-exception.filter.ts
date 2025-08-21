import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { ResponseDto } from '../dto/response.dto';

/**
 * 全局异常过滤器
 * 统一处理所有异常的响应数据格式
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status: number;
    let message: string;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const errorResponse = exception.getResponse();

      if (typeof errorResponse === 'string') {
        message = errorResponse;
      } else if (typeof errorResponse === 'object' && errorResponse !== null) {
        message = (errorResponse as any).message || exception.message;
        // 如果是验证错误，提取详细信息
        if (Array.isArray((errorResponse as any).message)) {
          message = (errorResponse as any).message.join(', ');
        }
      } else {
        message = exception.message;
      }
    } else {
      // 未知错误
      status = HttpStatus.INTERNAL_SERVER_ERROR;
      message = '服务器内部错误';

      // 在开发环境下显示详细错误信息
      if (process.env.NODE_ENV === 'development') {
        message = (exception as any)?.message || message;
        console.error('Unhandled exception:', exception);
      }
    }

    const errorResponse = ResponseDto.error(message, status);

    response.status(status).json(errorResponse);
  }
}
