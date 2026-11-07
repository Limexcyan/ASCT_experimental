import sys

import numpy as np
import torch
from scipy.io import loadmat, savemat
from fastica_torch import FastICA


def as_numpy(value):
    """Move a PyTorch tensor to CPU, or accept an existing NumPy array."""
    if isinstance(value, torch.Tensor):
        return value.detach().cpu().numpy()
    return np.asarray(value)


def main():
    # sys.argv includes the script name, followed by seven arguments.
    if len(sys.argv) != 8:
        raise SystemExit(
            "Usage: gpu_fastica.py INPUT OUTPUT APPROACH "
            "NONLINEARITY SEED MAX_ITER TOLERANCE"
        )

    (
        _, input_file, output_file, approach, nonlinearity,
        seed, max_iter, tolerance
    ) = sys.argv

    if not torch.cuda.is_available():
        raise RuntimeError(
            "ica.gpu=1, but this Python environment cannot access a CUDA GPU"
        )

    algorithms = {
        "defl": "deflation",
        "symm": "parallel",
    }
    functions = {
        "tanh": "logcosh",
        "pow3": "cube",
        "gauss": "exp",
    }

    approach = approach.lower()
    nonlinearity = nonlinearity.lower()

    if approach not in algorithms:
        raise ValueError(f"Unsupported approach: {approach}")
    if nonlinearity not in functions:
        raise ValueError(f"Unsupported nonlinearity: {nonlinearity}")

    data = loadmat(input_file)["sigs"]
    if data.ndim != 2 or np.iscomplexobj(data):
        raise ValueError("sigs must be a real channels × samples matrix")
    if not np.isfinite(data).all():
        raise ValueError("sigs contains NaN or Inf")

    seed = int(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)

    # Convert channels × samples into samples × channels.
    X = torch.as_tensor(
        np.ascontiguousarray(data.T),
        dtype=torch.float64,
        device="cuda",
    )

    model = FastICA(
        n_components=X.shape[1],
        algorithm=algorithms[approach],
        whiten="unit-variance",
        fun=functions[nonlinearity],
        max_iter=int(max_iter),
        tol=float(tolerance),
        random_state=seed,
    )

    with torch.no_grad():
        sources = model.fit_transform(X)

    savemat(output_file, {
        "IC_sig": as_numpy(sources).T,
        "IC_mix": as_numpy(model.mixing_),
        "IC_unmix": as_numpy(model.components_),
    })


if __name__ == "__main__":
    main()
