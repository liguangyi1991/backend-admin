/**
 * 统一响应数据结构
 */
export class ResponseDto<T = any> {
  /**
   * 状态码
   * 200: 成功
   * 400: 客户端错误
   * 500: 服务器错误
   */
  code: number;

  /**
   * 响应消息
   */
  message: string;

  /**
   * 响应数据
   */
  data?: T;

  /**
   * 时间戳
   */
  timestamp: string;

  constructor(code: number, message: string, data?: T) {
    this.code = code;
    this.message = message;
    this.data = data;
    this.timestamp = new Date().toISOString();
  }

  /**
   * 成功响应
   */
  static success<T>(data?: T, message: string = '操作成功'): ResponseDto<T> {
    return new ResponseDto(200, message, data);
  }

  /**
   * 失败响应
   */
  static error(message: string = '操作失败', code: number = 400): ResponseDto {
    return new ResponseDto(code, message);
  }
}
