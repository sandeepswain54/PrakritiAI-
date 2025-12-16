import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:service_app/model/conversation_model.dart';
import 'package:service_app/model/global.dart';
import 'package:service_app/views/Widgets/conversation_list_tile_ui.dart';
import 'package:service_app/views/conversation_screen.dart';

class Post extends StatefulWidget {
  const Post({super.key});

  @override
  State<Post> createState() => _PostState();
}

class _PostState extends State<Post> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
     stream: inboxViewModel.getConversations(),
     builder: (context,  dataSnapshot )
     {
      if(dataSnapshot.connectionState == ConnectionState.waiting){
return Center(
  child: CircularProgressIndicator(),
);
      }
      else {
        return ListView.builder(
          itemCount: dataSnapshot.data!.docs.length,
          itemExtent: MediaQuery.of(context).size.height/9,

          itemBuilder:(context,index){
          DocumentSnapshot snapshot = dataSnapshot.data!.docs[index];

          ConversationModel currentConversation = ConversationModel();
          currentConversation.getConversationInfoFromFirestore(snapshot);


    return InkResponse(
      onTap: (){
Get.to(()=>ConversationScreen(conversation: currentConversation,));
      },
      child: ConversationListTileUi(
      conversation:currentConversation));
   
          } );
      }
     },

    );
  }
}