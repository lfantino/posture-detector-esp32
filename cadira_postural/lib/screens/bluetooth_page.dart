import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import '../services/bluetooth_service.dart';
import '../posture_control.dart';

/// Pantalla de connexió BLE.
/// Permet a l'usuari escanejar dispositius BLE i connectar-se a l'ESP32-C5.
class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage>
    with SingleTickerProviderStateMixin {
  final BluetoothService _bt = BluetoothService.instance;

  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  int? _connectingIndex;

  StreamSubscription? _scanResultsSubscription;
  StreamSubscription? _isScanningSubscription;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    final granted = await _bt.requestPermissions();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cal concedir permisos Bluetooth per continuar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Subscriure als resultats de l'escaneig
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) setState(() => _scanResults = results);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) setState(() => _isScanning = scanning);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    if (_isScanning) FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _startScan() {
    setState(() => _scanResults = []);
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
  }

  Future<void> _connectToDevice(ScanResult result, int index) async {
    await FlutterBluePlus.stopScan();
    setState(() => _connectingIndex = index);

    final success = await _bt.connectToDevice(result.device);

    if (mounted) {
      setState(() => _connectingIndex = null);

      if (success) {
        // Assegurar que el PostureController usa Bluetooth
        final ctrl = PostureController.instance;
        if (ctrl.currentSource != DataSource.bluetooth) {
          await ctrl.switchSource(DataSource.bluetooth);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connectat a Cadira Postural! 🎉'),
            backgroundColor: Color(0xFFA8D5BA),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_bt.lastError ?? 'Error de connexió'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE6),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 16,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Color(0xFF2D3142), size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connexió Bluetooth',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142))),
                        Text('Connecta amb la cadira ESP32-C5 (BLE)',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Animated BT icon ────────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFB5A1E5)
                            .withOpacity(0.15 + _pulseController.value * 0.15),
                        const Color(0xFFB5A1E5).withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB5A1E5), Color(0xFF8C82D6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB5A1E5).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _bt.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Estat actual ────────────────────────────────────────────
            ValueListenableBuilder<BtConnectionState>(
              valueListenable: _bt.connectionState,
              builder: (context, state, _) => _buildStatusChip(state),
            ),

            const SizedBox(height: 20),

            // ── Llista de dispositius descoberts ─────────────────────────
            Expanded(
              child: _scanResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bluetooth_searching,
                              size: 64,
                              color: Colors.grey.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            _isScanning
                                ? 'Buscant "Cadira_Postural"...'
                                : 'Prem "Escanejar" per trobar l\'ESP32-C5.\nAssegura\'t que el dispositiu és encès.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DISPOSITIUS TROBATS',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                          const SizedBox(height: 8),
                          _buildScanResultList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),

      // ── FAB per escanejar ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? _stopScan : _startScan,
        backgroundColor: const Color(0xFFB5A1E5),
        foregroundColor: Colors.white,
        icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
        label: Text(_isScanning ? 'Aturar escaneig' : 'Escanejar dispositius'),
      ),
    );
  }

  Widget _buildStatusChip(BtConnectionState state) {
    Color color;
    IconData icon;
    String label;

    switch (state) {
      case BtConnectionState.connected:
        color = const Color(0xFF2ECC71);
        icon = Icons.check_circle;
        label = 'Connectat';
      case BtConnectionState.connecting:
        color = const Color(0xFFF39C12);
        icon = Icons.sync;
        label = 'Connectant...';
      case BtConnectionState.scanning:
        color = const Color(0xFF3498DB);
        icon = Icons.bluetooth_searching;
        label = 'Escanejant...';
      case BtConnectionState.error:
        color = const Color(0xFFE74C3C);
        icon = Icons.error;
        label = 'Error';
      case BtConnectionState.disconnected:
        color = Colors.grey;
        icon = Icons.bluetooth_disabled;
        label = 'Desconnectat';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildScanResultList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: _scanResults.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          final name = result.device.platformName.isNotEmpty
              ? result.device.platformName
              : result.advertisementData.advName;
          final displayName = name.isNotEmpty ? name : 'Dispositiu desconegut';
          final isEsp32 = displayName.contains(kEsp32DeviceName);
          final isConnecting = _connectingIndex == index;
          final rssi = result.rssi;

          return Column(
            children: [
              if (index > 0) const Divider(height: 1, indent: 60),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isEsp32
                        ? const Color(0xFFB5A1E5).withOpacity(0.15)
                        : const Color(0xFFF2F0F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEsp32 ? Icons.chair : Icons.bluetooth,
                    color: isEsp32
                        ? const Color(0xFFB5A1E5)
                        : const Color(0xFF9094A6),
                    size: 22,
                  ),
                ),
                title: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: isEsp32 ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                subtitle: Text(
                  '${result.device.remoteId.str}  ·  $rssi dBm',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: isConnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFB5A1E5),
                        ),
                      )
                    : isEsp32
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFB5A1E5),
                                  Color(0xFF8C82D6)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Connectar',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          )
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: isConnecting
                    ? null
                    : () => _connectToDevice(result, index),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
