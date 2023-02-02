import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:face_recognition_mobile/constants/api_constants.dart';
import 'package:face_recognition_mobile/model/add_request.dart';
import 'package:face_recognition_mobile/model/detect_request.dart';
import 'package:face_recognition_mobile/model/detect_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'face_state.dart';

class FaceCubit extends Cubit<FaceState> {
  FaceCubit() : super(FaceInitial());
  final _dio = Dio();

  Future<void> addFace(String name, File image) async {
    try {
      emit(FaceLoading());

      final request = AddRequest(
          image: base64.encode(await image.readAsBytes()), name: name);

      await _dio.post(
        '${APIConstants.baseUrl}${APIConstants.addUrl}',
        data: request.toJson(),
      );

      emit(AddFaceSuccess());
    } on DioError catch (e) {
      emit(FaceError(e.response!.data['message']));
    }
  }

  Future<void> detectFace(File image) async {
    try {
      emit(FaceLoading());

      final request = DetectRequest(
        image: base64.encode(await image.readAsBytes()),
      );

      final result = await _dio.post(
        '${APIConstants.baseUrl}${APIConstants.detectUrl}',
        data: request.toJson(),
      );

      emit(DetectFaceSuccess(DetectResponse.fromJson(result.data)));
    } on DioError catch (e) {
      emit(FaceError(e.response!.data['message']));
    }
  }
}
