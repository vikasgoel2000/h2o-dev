import sys
sys.path.insert(1, "../../../")
import h2o

def perfectSeparation_unbalanced(ip,port):
    # Connect to h2o
    h2o.init(ip,port)

    print("Read in synthetic unbalanced dataset")
    data = h2o.import_frame(h2o.locate("smalldata/synthetic_perfect_separation/unbalanced.csv"))

    print("Fit model on dataset.")
    model = h2o.glm(x=data[["x1", "x2"]], y=data["y"], family="binomial", lambda_search=True, use_all_factor_levels=True, alpha=[0.5], Lambda=[0])

    print("Extract models' coefficients and assert reasonable values (ie. no greater than 50)")
    print("Unbalanced dataset")
    coef = [c[1] for c in model._model_json['output']['coefficients_table'].cell_values if c[0] != "Intercept"]
    for c in coef:
        assert c < 50, "coefficient is too large"

if __name__ == "__main__":
    h2o.run_test(sys.argv, perfectSeparation_unbalanced)
