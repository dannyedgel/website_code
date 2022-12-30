import janitor
import argparse
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from os.path import join
from glob import glob


# load data
def load_streaming_data(path="../data", stub="endsong"):
    df = pd.concat([pd.read_json(f) for f in glob(join(path, f"{stub}*.json"))])
    
    if (stub == "endsong"):
        col_mapper = {
            "ts": "endTime",
            "ms_played": "msPlayed",
            "master_metadata_album_artist_name": "artistName",
            "master_metadata_album_name": "albumName",
            "master_metadata_track_name": "trackName"
        }
        df = df.rename(columns=col_mapper)
    
    return df
    

# clean data
def manipulate_streaming_data(df, year):
    
    # keep only 2022 data
    df = df[pd.to_datetime(df["endTime"]).dt.year == year]
    
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
def plot_normalized_minutes(df, cutoff, group):
    
    var_mapper = {
        "artists": "artistName",
        "albums": "albumName",
        "tracks": "trackName"
    }
    
    variable = var_mapper[group]
    year = pd.to_datetime(df["date"]).dt.year.unique()[0]
    
    # choose cutoff based on one+ month of data
    levels = df[pd.to_datetime(df["date"]).dt.month > 1]
    levels = levels[
        levels.groupby(variable)["cum_norm"].transform("max") >= cutoff][variable].drop_duplicates().to_list()
    
    df = df[df[variable].isin(levels)]
    df.sort_values([variable, "date"])
    df.index = pd.to_datetime(df["date"], infer_datetime_format=True)
    

    fig, ax = plt.subplots(figsize=(15, 7.5))
    for x in df[variable].drop_duplicates().to_list():
        ax.plot(df[df[variable].isin([x])]["cum_norm"], label=x)
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%b'))
    ax.xaxis.set_major_locator(mdates.MonthLocator(interval=1))
    ax.set_ylabel('Minutes normalized by top artist minutes')
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.05), frameon=False, fancybox=True, shadow=True, 
              ncol=9, title='Artist')
    plt.savefig(f'../output/{year}_streaming_{group}.png', bbox_inches='tight')

# main function
def main(year, stub, path, group, cutoff):
    # load and clean streaming data
    df = manipulate_streaming_data(load_streaming_data(stub=stub), year=year)
    
    # print names of artists that were ever top throughout the year
    print("\nArtists that were ever top artist:")
    print(df["top_artist"].drop_duplicates().to_list())
    
    # repeat with artists that ever reached 80% of the top artist
    print("\nArtists that ever reached 80% of the top artist:")
    print(df[df["cum_norm"] >= 0.8]["artistName"].drop_duplicates().to_list())
    
    # plot normalized minutes of top artists throughout the year
    plot_normalized_minutes(df, cutoff=cutoff, group=group)
    

# run main function
if __name__ == "__main__":
    
    # parse command line input
    parser = argparse.ArgumentParser()
    parser.add_argument("year", type=int, default=2022,
                        help="the year of data to plot")
    parser.add_argument("-s", "--stub", default="endsong", type=str,
                        help="Beginning of the file name of the data to load"
                        )
    parser.add_argument("-p", "--path", default="../data", type=str,
                        help="Filepath of the data to load (endsong or streaminghistory)",
                        )
    parser.add_argument("-g", "--group", default="artists", type=str,
                        help="Data to plot (artists, albums, tracks)",
                        )
    parser.add_argument("-c", "--cutoff", default=0.33, type=float,
                        help="Cutoff (between 0 and 1) for the minimum percentage of the top artist's minutes to plot",
                        )
    args = parser.parse_args()

    print("\nyear={}\nstub={}\npath={}\ngroup={}\ncutoff={}\n".format(
        args.year, args.stub, args.path, args.group, args.cutoff))    
    
    year, stub, path, group, cutoff = args.year, args.stub, args.path, args.group, args.cutoff
    
    main(year=year, stub=stub, path=path, group=group, cutoff=cutoff)
    