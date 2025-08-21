# 统一响应数据结构

## 概述

本项目使用统一的响应数据结构，包含 `code`、`message`、`data` 和 `timestamp` 字段。

## 响应格式

```typescript
{
  "code": 200,           // 状态码
  "message": "操作成功",  // 响应消息
  "data": {...},         // 响应数据（可选）
  "timestamp": "2024-01-01T00:00:00.000Z"  // 时间戳
}
```

## 状态码说明

- `200`: 操作成功
- `400`: 客户端错误（如参数验证失败）
- `401`: 未授权
- `403`: 禁止访问
- `404`: 资源不存在
- `500`: 服务器内部错误

## 使用方法

### 在控制器中使用

```typescript
import { ResponseDto } from '../common/dto/response.dto';

@Controller('example')
export class ExampleController {
  // 成功响应
  @Get()
  getData() {
    const data = { id: 1, name: '示例' };
    return ResponseDto.success(data, '获取数据成功');
  }

  // 也可以让全局拦截器自动包装
  @Get('auto')
  getDataAuto() {
    return { id: 1, name: '示例' }; // 会被自动包装成统一格式
  }

  // 错误响应（通过抛出异常）
  @Post()
  createData(@Body() dto: any) {
    if (!dto.name) {
      throw new HttpException('名称不能为空', HttpStatus.BAD_REQUEST);
    }
    return ResponseDto.success(dto, '创建成功');
  }
}
```

### 响应示例

#### 成功响应

```json
{
  "code": 200,
  "message": "获取数据成功",
  "data": {
    "id": 1,
    "name": "示例"
  },
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

#### 错误响应

```json
{
  "code": 400,
  "message": "名称不能为空",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## 自动化处理

- **全局响应拦截器**: 自动将所有成功的响应包装成统一格式
- **全局异常过滤器**: 自动将所有异常转换成统一的错误响应格式

## 注意事项

1. 如果控制器方法返回的已经是 `ResponseDto` 格式，拦截器不会重复包装
2. 所有未捕获的异常都会被全局异常过滤器处理
3. 验证错误会自动提取详细的错误信息
4. 在开发环境下，服务器错误会显示详细的错误信息
