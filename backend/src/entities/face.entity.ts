import { Face } from '@/interfaces/face.interface';
import { IsNotEmpty } from 'class-validator';
import { BaseEntity, Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity()
export class FaceEntity extends BaseEntity implements Face {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  @IsNotEmpty()
  name: string;

  @Column()
  @IsNotEmpty()
  face: string;

  @Column()
  gender: string;

  @Column()
  age: number;
}
