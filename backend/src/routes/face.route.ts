import { Router } from 'express';
import FaceController from '@controllers/face.controller';
import { Routes } from '@interfaces/routes.interface';
import validationMiddleware from '@middlewares/validation.middleware';
import { AddFaceDto, DetectFaceDto } from '@/dtos/face.dto';

class FaceRoute implements Routes {
  public path = '/face';
  public router = Router();
  public usersController = new FaceController();

  constructor() {
    this.initializeRoutes();
  }

  private initializeRoutes() {
    this.router.post(`${this.path}/add`, validationMiddleware(AddFaceDto, 'body'), this.usersController.addFace);
    this.router.post(`${this.path}/detect`, validationMiddleware(DetectFaceDto, 'body'), this.usersController.detectFace);
  }
}

export default FaceRoute;
