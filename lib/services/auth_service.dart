
//Propios Dart
import 'dart:convert';

//Packetes
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

//Enviroment
import 'package:chat/global/enviroment.dart';

//Modelos
import 'package:chat/models/login_response.dart';
import 'package:chat/models/usuario.dart';

class AuthService with ChangeNotifier {

  Usuario usuario;
  bool _autenticando = false;
  bool _registrando = false;

  final _storage = new FlutterSecureStorage();

  bool get autenticando => this._autenticando;
  set autenticando(bool valor){
    this._autenticando = valor;
    notifyListeners();
  }

  bool get registrando => this._registrando;
  set registrando(bool valor){
    this._registrando = valor;
    notifyListeners();
  }

  //Getteres del token de forma estatica
  static Future<String> getToken() async {

    final _storage = new FlutterSecureStorage();
    final token = await _storage.read(key: 'token');
    return token;

  }

  static Future<void> deleteoken() async {

    final _storage = new FlutterSecureStorage();
    await _storage.delete(key: 'token');
    

  }

  Future<bool> login( String email, String password ) async {

    this.autenticando = true;

    final data = {
      'email': email,
      'password': password
    };

    // print(Enviroment.apiUrl);
    final resp = await http.post('${ Enviroment.apiUrl }/login', 
      body: jsonEncode(data),
      headers: {
        'Content-Type': 'application/json'
      }
    );

    
    
    this.autenticando = false;

    if( resp.statusCode == 200 ){
      final loginResponse =  loginResponseFromJson( resp.body );

      this.usuario = loginResponse.usuario;

      //Guardar token en un lugar seguro
      this._guardarToken(loginResponse.token);

      return true;

    }
    else{
      return false;
    }

  }

  Future register(String nombre, String email, String password ) async {

    this.registrando = true;

    final data = {
      'nombre': nombre,
      'email': email,
      'password': password
    };

    final resp = await http.post('${ Enviroment.apiUrl }/login/new', 
      body: jsonEncode(data),
      headers: {
        'Content-Type': 'application/json'
      }
    );

    
    
    this.registrando = false;

    if( resp.statusCode == 200 ){
      final loginResponse =  loginResponseFromJson( resp.body );

      this.usuario = loginResponse.usuario;

      //Guardar token en un lugar seguro
      this._guardarToken(loginResponse.token);

      return true;

    }
    else{

      final respBody = jsonDecode(resp.body);
      
      return respBody['msg'];
    }

  }

  Future<bool> isLoggedIn() async {

    final token = await this._storage.read(key: 'token');

    final resp = await http.get('${ Enviroment.apiUrl }/login/renew', 
      headers: {
        'Content-Type': 'application/json',
        'x-token': token
      }
    );

    
    
    this.registrando = false;

    if( resp.statusCode == 200 ){
      final loginResponse =  loginResponseFromJson( resp.body );

      this.usuario = loginResponse.usuario;

      //Guardar token en un lugar seguro
      this._guardarToken(loginResponse.token);

      return true;

    }
    else{

      this.logout();
      return false;
    }

  }

  Future _guardarToken( String token ) async {

    return await _storage.write(key: 'token', value: token);

  } 

  Future logout() async {
    await _storage.delete(key: 'token');
  }

}