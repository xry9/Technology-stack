/* Replace "dll.h" with the name of your header */
#include "Hello.h"
#include <windows.h>
#include <iostream>

JNIEXPORT void JNICALL Java_NativeDemo_sayHello(JNIEnv *, jobject){
	using namespace std;
	cout << "Hello___________World";
}
