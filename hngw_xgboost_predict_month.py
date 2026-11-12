import argparse
import json
import os
import warnings

import numpy as np
import scipy.io as sio
from xgboost import XGBRegressor


def main():
    parser = argparse.ArgumentParser(description="Train one monthly XGBoost model and predict 0.25/0.01 GWSA.")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--month-index", type=int, default=1)
    parser.add_argument("--model-output", default="")
    parser.add_argument("--params-json", default="")
    args = parser.parse_args()

    warnings.filterwarnings("ignore", category=FutureWarning)
    data = sio.loadmat(args.input)
    x025 = np.asarray(data["X025"], dtype=np.float32)
    y025 = np.asarray(data["Y025"], dtype=np.float32).reshape(-1)
    x001 = np.asarray(data["X001"], dtype=np.float32)

    good = np.isfinite(y025) & np.all(np.isfinite(x025), axis=1)
    if int(good.sum()) < 10:
        raise RuntimeError(f"Not enough valid training samples: {int(good.sum())}")

    # Conservative defaults: Henan has only about 258 low-resolution samples.
    params = dict(
        objective="reg:squarederror",
        n_estimators=300,
        max_depth=3,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        reg_lambda=1.0,
        reg_alpha=0.0,
        min_child_weight=1.0,
        random_state=20260516 + args.month_index,
        n_jobs=4,
        tree_method="hist",
        verbosity=0,
    )
    params_text = args.params_json or os.environ.get("HNGW_XGB_PARAMS", "")
    if params_text:
        params.update(json.loads(params_text))

    model = XGBRegressor(
        **params,
    )
    model.fit(x025[good, :], y025[good])
    if args.model_output:
        model_dir = os.path.dirname(args.model_output)
        if model_dir:
            os.makedirs(model_dir, exist_ok=True)
        model.save_model(args.model_output)
        meta_output = os.path.splitext(args.model_output)[0] + "_meta.json"
        with open(meta_output, "w", encoding="utf-8") as f:
            json.dump(
                {
                    "month_index": args.month_index,
                    "model_type": "xgboost",
                    "valid_training_samples": int(good.sum()),
                    "n_features": int(x025.shape[1]),
                    "params": model.get_params(),
                    "feature_importances": model.feature_importances_.astype(float).tolist(),
                },
                f,
                ensure_ascii=False,
                indent=2,
            )
    ypred025 = model.predict(x025).astype(np.float64)
    ypred001 = model.predict(x001).astype(np.float64)

    sio.savemat(
        args.output,
        {
            "ypred025": ypred025.reshape(1, -1),
            "ypred001": ypred001.reshape(1, -1),
            "model_type": "xgboost",
        },
        do_compression=False,
    )


if __name__ == "__main__":
    main()
