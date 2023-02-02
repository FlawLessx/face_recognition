import App from '@/app';
import validateEnv from '@utils/validateEnv';
import FaceRoute from './routes/face.route';
import faceService from './services/face.service';

validateEnv();

const app = new App([new FaceRoute()]);
faceService.initModels();

app.listen();
