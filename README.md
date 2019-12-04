# Backtest v2
"Magic formula", up to monthly rebalance, long only, desktop app


#### Business case

Next step in evolution of the backtest, after it turned out that [web app form (v1)](https://github.com/Tim-K-DFW/vultures) was too slow at frequencies higher than annual, with no offsetting benefit.

#### Key features (diffs vs v1)

- supported multiple rebalancing frequencies between one year and one month
- in addition to performance summary for entire backtest period, the app generated complete audit trail with comprehensive portfolio snapshots at every rebalancing period, including ranking scores.

#### Design highlights (diffs vs v1)

- all of Rails is gone, pure Ruby with CLI, ran on desktop
- instead of simply reading in CSV files, began to pre-process data as a step separate from the simulation and store it in serialized form, which was a precursor to later multi-dimensional database setup.
