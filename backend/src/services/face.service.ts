import { EntityRepository, Repository } from 'typeorm';
import { FaceEntity } from '@/entities/face.entity';
import { AddFaceDto, DetectFaceDto } from '@/dtos/face.dto';
import { Face } from '@/interfaces/face.interface';
import * as tf from '@tensorflow/tfjs-node';
import * as faceapi from '@vladmandic/face-api';
import path from 'path';
import { logger } from '@/utils/logger';
import { HttpException } from '@/exceptions/HttpException';

@EntityRepository()
class FaceService extends Repository<FaceEntity> {
  public async addFace(faceData: AddFaceDto): Promise<any> {
    tf.engine().startScope();
    let alreadyRegistered = false;
    // Processing requested face
    const processedFaceData = await this.getFaceComputation(faceData.image);
    // All faces data in database
    const faces: Face[] = await FaceEntity.find();

    // Comparing requested face with all data
    for (let index = 0; index < faces.length; index++) {
      const element = faces[index];
      // Compute distance between 2 face
      const distance = faceapi.euclideanDistance(processedFaceData.descriptor, this.decodeBase64(element.face));

      // If distance below 0.3 it will recognized as same face
      // The smaller the value the better
      // But here i used 0.3
      if (distance < 0.3) {
        logger.info('Distances: ' + distance);
        alreadyRegistered = true;
        break;
      }
    }
    tf.engine().endScope();

    // If already registered returning bad request
    if (alreadyRegistered) {
      throw new HttpException(400, 'Face already registered');
    } else {
      // If not registered, save new data into database
      await FaceEntity.save({ ...processedFaceData, face: this.encodeBase64(processedFaceData.descriptor), name: faceData.name });
      return { message: 'Face successfully registered' };
    }
  }

  public async detectFace(faceData: DetectFaceDto): Promise<any> {
    tf.engine().startScope();
    let returnFace: Face;
    // Processing requested face
    const processedFaceData = await this.getFaceComputation(faceData.image);
    // All faces data in database
    const faces: Face[] = await FaceEntity.find();

    logger.info('Faces: ' + faces.length);

    // Comparing requested face with all data
    for (let index = 0; index < faces.length; index++) {
      const element = faces[index];
      // Compute distance between 2 face
      const distance = faceapi.euclideanDistance(processedFaceData.descriptor, this.decodeBase64(element.face));

      // If distance below 0.3 it will recognized as same face
      // The smaller the value the better
      // But here i used 0.3
      if (distance < 0.3) {
        logger.info('Distances: ' + distance);
        returnFace = element;
        break;
      }
    }
    tf.engine().endScope();

    // If face not undefined return result
    if (returnFace) {
      return returnFace;
    } else {
      throw new HttpException(400, 'Face not registered');
    }
  }

  // Load models from disk and only run once when startup
  public async initModels(): Promise<any> {
    try {
      const modelPathRoot = '../models';
      faceapi.tf.ENV.set('DEBUG', false);

      console.log('Loading FaceAPI models');
      const modelPath = path.join(__dirname, modelPathRoot);
      await faceapi.nets.ssdMobilenetv1.loadFromDisk(modelPath);
      await faceapi.nets.tinyFaceDetector.loadFromDisk(modelPath);
      await faceapi.nets.faceLandmark68Net.loadFromDisk(modelPath);
      await faceapi.nets.faceRecognitionNet.loadFromDisk(modelPath);
      await faceapi.nets.faceExpressionNet.loadFromDisk(modelPath);
      await faceapi.nets.ageGenderNet.loadFromDisk(modelPath);
    } catch (error) {
      logger.error(error);
    }
  }

  // Returning face descriptor, age, and gender
  private async getFaceComputation(base64Image: string): Promise<any> {
    const buffer = Buffer.from(base64Image, 'base64');
    const decoded = tf.node.decodeImage(buffer);
    const casted = decoded.toFloat();
    const tensor = casted.expandDims(0);
    const tfOptions = new faceapi.TinyFaceDetectorOptions();

    const result = await faceapi
      .detectSingleFace(tensor, tfOptions)
      .withFaceLandmarks()
      .withFaceExpressions()
      .withFaceDescriptor()
      .withAgeAndGender();

    // Disponse required for avoid memory leak
    tf.dispose([decoded, casted, tensor]);
    return result;
  }

  // Converting Float32Array descriptor into a base64 string for saving to database
  private encodeBase64(descriptor: any) {
    return btoa(String.fromCharCode(...new Uint8Array(descriptor.buffer)));
  }

  // Converting base64 string descriptor into a Float32Array
  // To be acceptable by tensorflow
  private decodeBase64(encodedDescriptor: any) {
    return new Float32Array(new Uint8Array([...atob(encodedDescriptor)].map(c => c.charCodeAt(0))).buffer);
  }
}

const faceService = new FaceService();
export default faceService;
