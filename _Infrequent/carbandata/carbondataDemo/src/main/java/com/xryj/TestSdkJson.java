package com.xryj;

import java.io.IOException;
import java.sql.Timestamp;
import java.util.Date;

import org.apache.carbondata.common.exceptions.sql.InvalidLoadOptionException;
import org.apache.carbondata.core.metadata.datatype.DataTypes;
import org.apache.carbondata.sdk.file.*;


public class TestSdkJson {

   public static void main(String[] args) throws InvalidLoadOptionException, IOException, InterruptedException {
       testJsonSdkWriter();
   }
   
   public static void testJsonSdkWriter() throws InvalidLoadOptionException, IOException, InterruptedException {
    String path = "./target/testJsonSdkWriter";

    Field[] fields = new Field[2];
    fields[0] = new Field("name", DataTypes.STRING);
    fields[1] = new Field("age", DataTypes.INT);

    Schema CarbonSchema = new Schema(fields);

    CarbonWriterBuilder builder = CarbonWriter.builder().outputPath(path).withJsonInput(CarbonSchema).writtenBy("SDK");

    CarbonWriter writer = builder.build();
    String  JsonRow = "{\"name\":\"abcd\", \"age\":10}";

    int rows = 5;
    for (int i = 0; i < rows; i++) {
      writer.write(JsonRow);
    }
    writer.close();

  }
    public static void testSdkReader() throws IOException, InterruptedException {
        String path = "./testWriteFiles";
        CarbonReader reader = CarbonReader
                .builder(path, "_temp")
                .projection(new String[]{"stringField", "shortField", "intField", "longField",
                        "doubleField", "boolField", "dateField", "timeField", "decimalField"})
                .build();

        // 2. Read data
        long day = 24L * 3600 * 1000;
        int i = 0;
        while (reader.hasNext()) {
            Object[] row = (Object[]) reader.readNextRow();
            System.out.println(String.format("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
                    i, row[0], row[1], row[2], row[3], row[4], row[5],
                    new Date((day * ((int) row[6]))), new Timestamp((long) row[7] / 1000), row[8]
            ));
            i++;
        }

        // 3. Close this reader
        reader.close();
    }
} 