
import janitor
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from os.path import join
from glob import glob


# load data
def load_streaming_data(path="../data"):
    return pd.concat([pd.read_json(f) for f in glob(join(path, "StreamingHistory*.json"))])

# clean data
def manipulate_streaming_data(df):
    
    # keep only 2022 data
    df = df[pd.to_datetime(df["endTime"]).dt.year == 2022]
    
    df["date"] = pd.to_datetime(df.endTime).dt.date
    df["minutes_played"] = df.msPlayed / 1000 / 60
    
    
    df = df.groupby(["artistName", "date"]).agg({"minutes_played": "sum"}).reset_index().sort_values(
        ["date", "minutes_played"], ascending=[True, False])
    df["artist_cumulative"] = df.groupby(["artistName"])["minutes_played"].cumsum()
    df = df.complete('artistName', 'date')
    df["artist_cumulative"] = df.groupby('artistName')['artist_cumulative'].ffill().fillna(0)
    df["top_artist_minutes"] = df.groupby("date")["artist_cumulative"].transform("max")
    df = df.merge(
        df[df["artist_cumulative"] == df["top_artist_minutes"]][["date", "artistName"]].rename(
            columns={"artistName": "top_artist"})
    ).sort_values(["date", "artistName"])
    df["cum_norm"] = df["artist_cumulative"] / df["top_artist_minutes"]
    
    return df


# plotting function
def plot_normalized_minutes(df, cutoff=.5):
    df = df[df.groupby("artistName")["cum_norm"].transform("max") >= cutoff]
    df.sort_values(["artistName", "date"])
    df["date"] = pd.to_datetime(df["date"], infer_datetime_format=True)

    fig, ax = plt.subplots(figsize=(15, 7.5))
    for x in df["artistName"].drop_duplicates().to_list():
        ax.plot(df[df["artistName"].isin([x])]["date"], df[df["artistName"].isin([x])]["cum_norm"], label=x)
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%b'))
    ax.xaxis.set_minor_formatter(mdates.DateFormatter('%b'))
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.05),
            fancybox=True, shadow=True, ncol=9, title='Artist')
    plt.savefig('../output/2022_streaming_artists.png', bbox_inches='tight')

# main function
def main():
    # load and clean streaming data
    df = manipulate_streaming_data(load_streaming_data())
    
    # print names of artists that were ever top throughout the year
    print("Artists that were ever top artist:\n")
    print(df["top_artist"].drop_duplicates().to_list())
    
    # repeat with artists that ever reached 80% of the top artist
    print("Artists that ever reached 80% of the top artist:\n")
    print(df[df["cum_norm"] >= 0.8]["artistName"].drop_duplicates().to_list())
    
    # plot normalized minutes of top artists throughout the year
    plot_normalized_minutes(df)
    

# run main function
if __name__ == "__main__":
    main()
    