import com.lucidworks.spark.ml.MLComponent;
import com.lucidworks.spark.ml.MLModel;
import hex.genmodel.easy.EasyPredictModelWrapper;
import org.apache.spark.mllib.feature.HashingTF;
import com.lucidworks.spark.analysis.LuceneTextAnalyzer;
import org.apache.spark.mllib.linalg.Vector;
import org.apache.spark.mllib.feature.Normalizer;
import java.io.File;
import java.util.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Created by akashmehta on 8/1/16.
 */
public class H2oGBMmodel implements MLModel {
  private static final Logger log = LoggerFactory.getLogger(H2oGBMmodel.class);
  public static final String TYPE = "h2o-model";
  private static final String stdTokLowerSchema ="{ \"analyzers\": [{ \"name\": \"std_tok_lower\", \"tokenizer\": { \"type\": \"standard\" },\n" + "\"filters\": [{ \"type\": \"lowercase\" }]}],\n" +"  \"fields\": [{ \"regex\": \".+\", \"analyzer\": \"std_tok_lower\" }]}\n";
  private static final String modelClassName = "gbm_6ee6a127_4ef6_431f_963f_2ba865f2260e";
  protected LuceneTextAnalyzer textAnalyzer;
  protected HashingTF hashingTF;
  protected String[] featureFields;
  public hex.genmodel.GenModel rawModel;
  public EasyPredictModelWrapper model;
  protected String modelId;

  public String getId() {
    return modelId;
  }

  public String getType() {
    return TYPE;
  }

  public String[] getFeatureFields() {
    return featureFields;
  }

  public void init(String modelId, File modelDir, Map<String,Object> modelSpecJson) throws Exception {
    this.modelId = modelId;
    this.rawModel = (hex.genmodel.GenModel) Class.forName(modelClassName).newInstance();
    this.model = new EasyPredictModelWrapper(this.rawModel);
    List<String> fields = (List<String>)modelSpecJson.get(MLComponent.ML_METADATA_MODEL_FEATURE_FIELDS);

    if (fields == null) {
      throw new IllegalArgumentException(MLComponent.ML_METADATA_MODEL_FEATURE_FIELDS+
              " is required metadata for "+TYPE+" based models!");
    }
    this.featureFields = fields.toArray(new String[0]);
    for (int f=0; f < featureFields.length; f++) {
      featureFields[f] = featureFields[f].trim(); // allow ws between names in the raw metadata
    }
  }



  public List<String> prediction(Object[] tuple) throws Exception {
    textAnalyzer = new LuceneTextAnalyzer(stdTokLowerSchema);
    LinkedList terms = new LinkedList();
    String prediction;
    for(int vector = 0; vector < tuple.length; ++vector) {
      Object col = tuple[vector];
      if(col != null) {
        terms.addAll(textAnalyzer.analyzeJava(this.featureFields[vector], col.toString()));
      }
    }
    int dim=(int)Math.pow(2,10);
    hashingTF=new HashingTF(dim);
    Normalizer normalizer=new Normalizer();
    Vector vectors = normalizer.transform(this.hashingTF.transform(terms));
    double[] probabilities=rawModel.score0(vectors.toArray(),new double[this.rawModel.nclasses()+1]);
    prediction=model.getResponseDomainValues()[(int)probabilities[0]];
    return (prediction != null) ? Collections.singletonList(String.valueOf(prediction)) : Collections.EMPTY_LIST;
  }

}
