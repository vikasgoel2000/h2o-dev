import sys
sys.path.insert(1, "../../../")
import h2o

def getModelGBM(ip,port):
  # Connect to h2o
  h2o.init(ip,port)

  prostate = h2o.import_frame(path=h2o.locate("smalldata/logreg/prostate.csv"))
  #prostate.summary()
  prostate_gbm = h2o.gbm(y=prostate[1], x=prostate[2:9], nfolds=5, loss="bernoulli")
  prostate_gbm.show()

  # Can't specify both nfolds >= 2 and validation data at once
  try:
    h2o.gbm(y=prostate[1], x=prostate[2:9], nfolds=5, validation_y=prostate[1], validation_x=prostate[2:9], loss="bernoulli")
    assert False, "expected an error"
  except EnvironmentError:
    assert True

  prostate_gbm.predict(prostate)
  model = h2o.getModel(prostate_gbm._key)
  model.show()

if __name__ == "__main__":
  h2o.run_test(sys.argv, getModelGBM)
