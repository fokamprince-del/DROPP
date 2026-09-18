import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsNotEmpty,
  MaxLength,
} from 'class-validator';

export class RenvoiCodeDto {
  @Transform(({ value }) =>
    typeof value === 'string'
      ? value.trim().toLowerCase()
      : value,
  )
  @IsEmail()
  @IsNotEmpty()
  @MaxLength(254)
  email!: string;
}