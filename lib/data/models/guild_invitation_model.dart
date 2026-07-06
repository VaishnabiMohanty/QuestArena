import 'package:cloud_firestore/cloud_firestore.dart';

class GuildInvitationModel {
  final String id;
  final String guildId;
  final String guildName;
  final String guildIconId;
  final String senderUid;
  final String senderName;
  final String receiverUid;
  final DateTime sentAt;

  GuildInvitationModel({
    required this.id,
    required this.guildId,
    required this.guildName,
    required this.guildIconId,
    required this.senderUid,
    required this.senderName,
    required this.receiverUid,
    required this.sentAt,
  });

  factory GuildInvitationModel.fromJson(Map<String, dynamic> json) {
    return GuildInvitationModel(
      id: json['id'] ?? '',
      guildId: json['guildId'] ?? '',
      guildName: json['guildName'] ?? '',
      guildIconId: json['guildIconId'] ?? '1',
      senderUid: json['senderUid'] ?? '',
      senderName: json['senderName'] ?? '',
      receiverUid: json['receiverUid'] ?? '',
      sentAt: (json['sentAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'guildId': guildId,
    'guildName': guildName,
    'guildIconId': guildIconId,
    'senderUid': senderUid,
    'senderName': senderName,
    'receiverUid': receiverUid,
    'sentAt': Timestamp.fromDate(sentAt),
  };
}
