package  com.shengyou.mj;

import java.security.MessageDigest;

public class MD5 {
	 public static String encrypt(String s)
	    {
	        if(s==null) return "";
	        byte buff[]=s.getBytes();
	        try 
	        {
	            MessageDigest messagedigest = MessageDigest.getInstance("MD5");
	            messagedigest.update(buff);
	            byte result[] = messagedigest.digest();
	            return byte2Hex(result);
	        }
	        catch(Exception e)
	        {
	            return "";
	        }
	    }

	    public static String byte2Hex(byte b[])
	    { 
	        if(b==null) return "";
	        StringBuffer tmp=new StringBuffer();
	        int len=b.length;
	        for(int i=0;i<len;i++)
	        {
	            String s=Integer.toHexString(b[i] & 0XFF);
	            if(s.length()<2) tmp.append('0');
	            tmp.append(s);
	        }
	        while(tmp.length()<16) tmp.append("00");
	        
	        return tmp.toString();
	    }
	    public static void main(String[] args) {
			System.out.println(encrypt("ngc2014"));
		}
}


