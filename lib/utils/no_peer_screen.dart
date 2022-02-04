//Package imports
import 'package:flutter/material.dart';

class NoPeerScreen extends StatelessWidget {

  const NoPeerScreen({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Padding(
            padding: EdgeInsets.only(bottom: 20.0),
            child: Text(
              "Looking for peers...",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ) 

        ],
      ),
    );
  }
}
