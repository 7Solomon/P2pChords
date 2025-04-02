class DeviceInfo {
  final String endpointName;
  final String serviceId;
  final String? connectionType; // 'nearby' or 'websocket'

  DeviceInfo(this.endpointName, this.serviceId, [this.connectionType = 'nearby']);
}
