import { z } from 'zod';

export const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  // Full connection string (Neon, Render...). If present, it wins over the DB_* variables
  // Cadena de conexión completa (Neon, Render...). Si existe, tiene prioridad sobre las DB_*
  DATABASE_URL: z.string().url().optional(),
  DB_HOST: z.string().optional(),
  DB_PORT: z.coerce.number().optional(),
  DB_USERNAME: z.string().optional(),
  DB_PASSWORD: z.string().optional(),
  DB_NAME: z.string().optional(),
  DB_SYNC: z.enum(['true', 'false']).default('false').transform((v) => v === 'true'),
  JWT_SECRET: z.string().min(16),
  // Accepts "3600" (seconds) or "1h", "30m", "7d"
  // Acepta "3600" (segundos) o "1h", "30m", "7d"
  JWT_EXPIRES_IN: z.string().regex(/^\d+[smhd]?$/).default('1h'),
  // Comma-separated list turned into an array: "key1,key2" -> ['key1', 'key2']
  // Lista separada por comas convertida en arreglo: "key1,key2" -> ['key1', 'key2']
  API_KEYS: z
    .string()
    .transform((v) => v.split(',').map((key) => key.trim()).filter(Boolean))
    .pipe(z.array(z.string()).min(1)),
}).refine((env) => env.DATABASE_URL || env.DB_HOST, {
  message: 'Define DATABASE_URL or the DB_* variables (Define DATABASE_URL o las variables DB_*)',
});

export type Env = z.infer<typeof envSchema>;
