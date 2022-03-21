public  class NativeDemo {
	{
		System.load("C:\\Users\\Administrator\\Desktop\\com\\Hello.dll");
	}

	public native void sayHello();
	
	
	public static void main(String[] args) {
		new NativeDemo().sayHello();
	}
}
