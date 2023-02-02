import { NextFunction, Request, Response } from 'express';
import faceService from '@/services/face.service';
import { AddFaceDto, DetectFaceDto } from '@/dtos/face.dto';

class FaceController {
  public addFace = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const faceData: AddFaceDto = req.body;
      const result = await faceService.addFace(faceData);

      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  };

  public detectFace = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const faceData: DetectFaceDto = req.body;
      const result = await faceService.detectFace(faceData);

      res.status(200).json({ message: 'Face successfully recognized', ...result });
    } catch (error) {
      next(error);
    }
  };
}

export default FaceController;
