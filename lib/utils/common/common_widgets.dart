// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';

class CommonButton extends StatelessWidget {
  final String buttonText;
  final Function onTap;
  const CommonButton(
      {super.key, required this.buttonText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(30.0),
      color: AppColors.primaryColor,
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        onPressed: () {
          onTap.call();
        },
        child: Text(
          buttonText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// class CommonTextField extends StatelessWidget {
//   final TextEditingController controller;
//   final String hintText;
//   final bool obscureText;
//   final TextStyle style;
//   final double borderRadius;

//   const CommonTextField({
//     super.key,
//     required this.controller,
//     required this.hintText,
//     this.obscureText = false,
//     required this.style,
//     this.borderRadius = 32, required IconButton suffixIcon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: controller,
//       obscureText: obscureText,
//       style: style,
//       decoration: InputDecoration(
//         contentPadding: const EdgeInsets.fromLTRB(20.0,5.0, 20.0, 5.0),
//         hintText: hintText,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(borderRadius),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(borderRadius),
//           borderSide: const BorderSide(color: AppColors.primaryColor),
//         ),
//       ),
//     );
//   }
// }



class CommonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextStyle style;
  final double borderRadius;
  // final IconButton? suffixIcon;
  final Widget? suffixIcon;  

  const CommonTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    required this.style,
    this.borderRadius = 32,
    this.suffixIcon, 
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: style,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5.0),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
        suffixIcon: suffixIcon, 
      ),
    );
  }
}



class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool automaticallyImplyLeading;
  final Color backgroundColor;
  final Function? onBackTap;
  final bool isAction;
  final Function? onAction;
  final Widget? actions;

  const CommonAppBar(
      {super.key,
      required this.title,
      this.automaticallyImplyLeading = true,
      this.backgroundColor = AppColors.primaryColor,
      this.onBackTap,
      this.isAction = false,
      this.onAction,  this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: automaticallyImplyLeading
          ? GestureDetector(
              onTap: () {
                if (onBackTap != null) {
                  onBackTap!();
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: backgroundColor,
      actions: [actions??SizedBox.shrink()],

    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CommonLabelText extends StatelessWidget {
  final String labelText;
  const CommonLabelText({super.key, required this.labelText});

  @override
  Widget build(BuildContext context) {
    return Text(
      labelText,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class CommonTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextStyle style;

  const CommonTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: style,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}
