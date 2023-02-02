part of 'face_cubit.dart';

@immutable
abstract class FaceState {}

class FaceInitial extends FaceState {}

class FaceLoading extends FaceState {}

class AddFaceSuccess extends FaceState {}

class DetectFaceSuccess extends FaceState {
  final DetectResponse data;

  DetectFaceSuccess(this.data);
}

class FaceError extends FaceState {
  final String message;

  FaceError(this.message);
}
