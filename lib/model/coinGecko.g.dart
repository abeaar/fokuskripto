// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coinGecko.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CoinGeckoMarketModelAdapter extends TypeAdapter<CoinGeckoMarketModel> {
  @override
  final int typeId = 0;

  @override
  CoinGeckoMarketModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CoinGeckoMarketModel(
      id: fields[0] as String,
      symbol: fields[1] as String,
      name: fields[2] as String,
      image: fields[3] as String,
      currentPrice: fields[4] as double,
      marketCap: fields[5] as double?,
      marketCapRank: fields[6] as int?,
      totalVolume: fields[7] as double?,
      high24h: fields[8] as double?,
      low24h: fields[9] as double?,
      priceChange24h: fields[10] as double?,
      priceChangePercentage24h: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, CoinGeckoMarketModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.image)
      ..writeByte(4)
      ..write(obj.currentPrice)
      ..writeByte(5)
      ..write(obj.marketCap)
      ..writeByte(6)
      ..write(obj.marketCapRank)
      ..writeByte(7)
      ..write(obj.totalVolume)
      ..writeByte(8)
      ..write(obj.high24h)
      ..writeByte(9)
      ..write(obj.low24h)
      ..writeByte(10)
      ..write(obj.priceChange24h)
      ..writeByte(11)
      ..write(obj.priceChangePercentage24h);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoinGeckoMarketModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
