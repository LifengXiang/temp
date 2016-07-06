import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

class SplitRunnable implements Runnable {
	int byteSize;
	String partFileName;
	File originFile;
	int startPos;

	public SplitRunnable(int byteSize, int startPos, String partFileName,
			File originFile) {
		this.startPos = startPos;
		this.byteSize = byteSize;
		this.partFileName = partFileName;
		this.originFile = originFile;
	}

	public void run() {
		RandomAccessFile rFile;
		OutputStream os;
		try {
			rFile = new RandomAccessFile(originFile, "r");
			byte[] b = new byte[byteSize];
			rFile.seek(startPos);// 移动指针到每“段”开头
			int s = rFile.read(b);
			os = new FileOutputStream(partFileName);
			os.write(b, 0, s);
			os.flush();
			os.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}

public class Base64Test {

	public static final String js = "C:\\Users\\apple\\Desktop\\javascript.pdf";

	public static void main(String[] args) throws Exception {
		splitBySize("C:\\tmp\\js2.txt",1024*1024);
		//FileUtil util = new FileUtil();
		//util.mergePartFiles("C:\\tmp", "part", 1024*1024*5, "C:\\tmp\\js3.txt");
		//toPdf();
	}

	public static void toPdf() throws Exception {
		BufferedReader reader = new BufferedReader(new InputStreamReader(
				new FileInputStream("C:\\tmp\\js3.txt")));
		OutputStream out = new FileOutputStream(new File("C:\\tmp\\js3.pdf"));
		String line;
		while ((line = reader.readLine()) != null) {
			byte[] bs = decode(line);
			out.write(bs);
		}
		reader.close();
		out.close();
	}

	public static void toTxt() throws Exception {
		InputStream in = new FileInputStream(new File(js));
		FileWriter writer = new FileWriter("C:\\tmp\\js2.txt");
		byte[] bs = new byte[1024];
		while (in.read(bs) != -1) {
			String s = encode(bs);
			writer.write(s);
		}
		in.close();
		writer.close();
	}

	public static String encode(byte[] bstr) {
		return new sun.misc.BASE64Encoder().encode(bstr);
	}

	public static byte[] decode(String str) {
		byte[] bt = null;
		try {
			sun.misc.BASE64Decoder decoder = new sun.misc.BASE64Decoder();
			bt = decoder.decodeBuffer(str);
		} catch (IOException e) {
			e.printStackTrace();
		}

		return bt;
	}

	/**
	 * 拆分文件
	 * 
	 * @param fileName
	 *            待拆分的完整文件名
	 * @param byteSize
	 *            按多少字节大小拆分
	 * @return 拆分后的文件名列表
	 * @throws IOException
	 */
	public static List<String> splitBySize(String fileName, int byteSize)
			throws IOException {
		List<String> parts = new ArrayList<String>();
		File file = new File(fileName);
		int count = (int) Math.ceil(file.length() / (double) byteSize);
		int countLen = (count + "").length();
		ThreadPoolExecutor threadPool = new ThreadPoolExecutor(count,
				count * 3, 1, TimeUnit.SECONDS,
				new ArrayBlockingQueue<Runnable>(count * 2));

		for (int i = 0; i < count; i++) {
			String partFileName = file.getName() + "."
					+ FileUtil.leftPad((i + 1) + "", countLen, '0') + ".part";
			System.out.println(partFileName);
			threadPool.execute(new SplitRunnable(byteSize, i * byteSize,
					partFileName, file));
			parts.add(partFileName);
		}
		return parts;
	}
	

}
