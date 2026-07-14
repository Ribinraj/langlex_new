import 'package:flutter/material.dart';

class AppRoutes {
  const AppRoutes._();

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const verifyOtp = '/verify-otp';
  static const dashboard = '/dashboard';
  static const upcomingRenewals = '/upcoming-renewals';
  static const recentlyRenewed = '/recently-renewed';
  static const editVehicle = '/edit-vehicle';
  static const editProfile = '/edit-profile';
  static const addVehicle = '/add-vehicle';
  static const employees = '/employees';
  static const addEmployee = '/add-employee';
  static const editEmployee = '/edit-employee';
  static const profile = '/profile';
  static const notifications = '/notifications';
}

@Deprecated('Use AppRoutes instead.')
class Approtes {
  static final RouteObserver<ModalRoute<void>> routeObserver =
      AppRoutes.routeObserver;

  static const splash = AppRoutes.splash;
  static const login = AppRoutes.login;
  static const signup = AppRoutes.signup;
  static const verifyOtp = AppRoutes.verifyOtp;
  static const dashboard = AppRoutes.dashboard;
  static const upcomingRenewals = AppRoutes.upcomingRenewals;
  static const recentlyRenewed = AppRoutes.recentlyRenewed;
  static const editVehicle = AppRoutes.editVehicle;
  static const editProfile = AppRoutes.editProfile;
  static const addVehicle = AppRoutes.addVehicle;
  static const employees = AppRoutes.employees;
  static const addEmployee = AppRoutes.addEmployee;
  static const editEmployee = AppRoutes.editEmployee;
  static const profile = AppRoutes.profile;
  static const notifications = AppRoutes.notifications;
}
