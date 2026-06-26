import 'package:intl/intl.dart';

NumberFormat currencyFormatter() =>
    NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 0);
