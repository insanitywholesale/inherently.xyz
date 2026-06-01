---
title: "One Billion Rows Challenge"
date: 2026-06-01T21:32:29+03:00
draft: false
tags: ["programming", "golang"]
---

A couple of years ago I found an interesting programming challenge that includes reading a lot of data and calculating aggregates on them.
It's called the "One Billion Rows Challenge" or 1brc for short.
I decided to take on the challenge to see how far I could get and I'd like to introduce others to it because I had fun participating.

## The challenge

As the [original challenge blog post](https://www.morling.dev/blog/one-billion-row-challenge/) and the equivalent [github repository README](https://github.com/gunnarmorling/1brc#1%EF%B8%8F%E2%83%A3%EF%B8%8F-the-one-billion-row-challenge) both explain, is the following:

> Your mission, should you decide to accept it, is deceptively simple: write a Java program for retrieving temperature measurement values from a text file and calculating the min, mean, and max temperature per weather station. There’s just one caveat: the file has 1,000,000,000 rows!
>
> The text file has a simple structure with one measurement value per row:
>
> ```
> Hamburg;12.0
> Bulawayo;8.9
> Palembang;38.8
> St. John's;15.2
> Cracow;12.6
> ...
> ```
>
> The program should print out the min, mean, and max values per station, alphabetically ordered like so:
>
> ```
> {Abha=5.0/18.0/27.4, Abidjan=15.7/26.0/34.1, Abéché=12.1/29.4/35.6, Accra=14.7/26.4/33.1, Addis Ababa=2.1/16.0/24.3, Adelaide=4.1/17.3/29.7, ...}
> ```
>
> The goal of the 1BRC challenge is to create the fastest implementation for this task, and while doing so, explore the benefits of modern Java and find out how far you can push this platform. So grab all your (virtual) threads, reach out to the Vector API and SIMD, optimize your GC, leverage AOT compilation, or pull any other trick you can think of.

The rules (I'm quoting the github README here):

> 1. Any of these Java distributions may be used:
>     1. Any builds provided by SDKMan
>     1. Early access builds available on openjdk.net may be used (including EA builds for OpenJDK projects like Valhalla)
>     1. Builds on [builds.shipilev.net](https://builds.shipilev.net/) If you want to use a build not available via these channels, reach out to discuss whether it can be considered.
> 1. No external library dependencies may be used
> 1. Implementations must be provided as a single source file
> 1. The computation must happen at application runtime, i.e. you cannot process the measurements file at build time (for instance, when using GraalVM) and just bake the result into the binary
> 1. Input value ranges are as follows:
>     1. Station name: non null UTF-8 string of min length 1 character and max length 100 bytes, containing neither `;` nor `\n` characters. (i.e. this could be 100 one-byte characters, or 50 two-byte characters, etc.)
>     1. Temperature value: non null double between -99.9 (inclusive) and 99.9 (inclusive), always with one fractional digit
> 1. There is a maximum of 10,000 unique station names
> 1. Line endings in the file are `\n` characters on all platforms
> 1. Implementations must not rely on specifics of a given data set, e.g. any valid station name as per the constraints above and any data distribution (number of measurements per station) must be supported
> 1. The rounding of output values must be done using the semantics of IEEE 754 rounding-direction "roundTowardPositive"

This was written from the perspective of the author wanting more people to learn about features in Java versions after 8 and possible performance optimizations that can be made using those features.
It also points to alternative compilers and runtimes so people can experiment more with parts of the software stack that might be considered infrastructure and as such neglected by developers.
When I read about it, I liked the idea of the challenge.
One billion rows is a significant amount, the file itself is 13GB on my system so doing anything with it in a reasonable amount of time is complicated.
I mean, even just generating the input is complicated enough, let alone implementing something that reads a 13GB file and computes aggregates in the end.
The rules provide details that inform which optimizations we are allowed to make and which ones are off the table.

The premise got me curious enough to sit down and write a program that did the naive thing knowing it was sub-optimal at best.
I spent several evenings optimizing it, failing to do so and then trying again.
Having seen the leaderboards (both the official ones for Java as well as community-built ones for other languages) I know my solution is not fast and there is room for improvement.

## My proposed alternative challenge

I like the rules of the original and I would like to enhance them.
Mainly, I'm not interested in a Java-only solution, I'd like everyone to be able to use whatever language they prefer.
The restriction of not doing build-time calculations stands and I want to expand it, the measurements file should only be accessed at runtime so something like using Go's `embed.FS` is not allowed.
Other than that, I would suggest trying to avoid memory mapping the file and using unsafe parts of a language at first and see how far you can get without it.
And with that, I think the challenge is explained well enough so we can get started with looking at my take on it.

## Solution in Go

My solution for the challenge is located at [gitlab.com/insanitywholesale/ongoing/x/1brc](https://gitlab.com/insanitywholesale/ongoing/-/blob/master/x/1brc/main.go?ref_type=heads).
It's a single file and split into functions with plenty of comments so I don't forget what I was trying to do which hopefully makes it easier to understand.

### The `TempStat` struct

Starting off with the data structure that stores the aggregates for one station, we have the `TempStat` struct:

{{< highlight go >}}
// TempStat stores measurement data for a station
type TempStat struct {
	Min   int64
	Max   int64
	Sum   int64
	Count int64
}
{{< /highlight >}}

This is the final form after optimizations so there are a couple surprising things.
First, the numbers are floating point in the input data but here we have integers.
This is because it was faster to multiply by 10 (we know that values are in the `[-99.9,99.9]` range) because comparing integers is faster (but for parsing the opposite is true).
Second, this is per-station so we need some place where all the results are stored, this is done in `main()` in a [`sync.Map`](https://pkg.go.dev/sync#Map) which we will look at afterwards.
We also don't calculate the average directly, we're storing the sum and count which allows for calculating it once at the end.

### Opening the file

To start off, we need to open the file generated from the challenge repository.
I haven't done any optimization here although I'm aware others have memory-mapped the file.
This is a simple function that returns a [`os.File`](https://pkg.go.dev/os#File):

{{< highlight go >}}
// OpenMeasurementsFile reads and returns the file containing measurements
func OpenMeasurementsFile() *os.File {
	// Assume file is next to binary
	fileName := "measurements.txt"
	// Unless it's provided as a CLI argument
	if len(os.Args) > 1 {
		fileName = os.Args[1]
	}
	// After determining the path, open it
	file, err := os.Open(fileName)
	if err != nil {
		// If it doesn't exist just panic, there is no point continuing
		panic(err)
	}
	// And return the handle
	return file
}
{{< /highlight >}}

It's fairly obvious this is for a challenge, normally I wouldn't leave a user-facing stacktrace from `panic()`.
Here it worked well enough to remind me "you don't have the file here and you didn't provide it as an argument, plzfix kthx bai!~".

### Processing the input

Now that we've opened the file, we have to start reading it and doing our calculations.
As a performance optimization, one that most people would do by default, I'm reading the measurement and updating the statistics all once.
However, a less obvious one that I implemented was to read more than one line at a time.
For this reason I have the `ProcessLineGroup` function which receives a list of lines as a first argument (through a channel, I'll explain more in the part about the `main()` function) and then sends each one of them to the `ProcessLine` function for the actual work to be done.
In this case, `ProcessLineGroup()` acts like a barrier between the goroutine-aware `main()` and the unaware `ProcessLine()`.
The `wg` referenced here is a global variable defined as `var wg sync.WaitGroup`.
In Go, a [`sync.WaitGroup`](https://pkg.go.dev/sync#WaitGroup) is a construct used for synchronization.
It has a counter which gets incremented by `Add(x)` and decremented by `Done()`.
When the counter is zero, all goroutines being blocked by the waitgroup will then continue.
It also takes a second argument, the results map, to make it accessible to `ProcessLine`.
Here is the code definition for the above:

{{< highlight go >}}
// ProcessLineGroup reads a batch of lines from the channel and processes them
func ProcessLineGroup(c chan []string, results *sync.Map) {
	// Mark goroutine as being done after ProcessLine exits
	defer wg.Done()

	// Read groups of lines from the channel
	for lines := range c {
		// Process each line in the group
		for _, line := range lines {
			ProcessLine(line, results)
		}
	}
}
{{< /highlight >}}

Going a bit deeper, we'll look at `ProcessLine()`.
After a single line, one measurement about one station, has been passed to be processed, let's see what happens to it.
We know the format is station name then a semicolon and then a floating-point temperature reading.
The fastest idiomatic way I found for doing this was to find the index of the semicolon and then make two string slices, one starting at the beginning of the line and ending before it and one starting after it and ending at the end of the line.
Next, we parse it as a float because it's faster (I played around with this part quite a bit, it's been over a year since I wrote the program so I'm not sure how I was parsing it as an int) and also discard any errors to avoid an extra `if`.
Then we get into the conversion that was hinted at by `TempStat` and store that value in the temporary temperature variable `temp`
Since we have guarantees about the input we can afford to do this without checking, in any other case this would lead to incorrect results.
The [`results.LoadOrStore`](https://pkg.go.dev/sync#Map.LoadOrStore) call either returns the value for the key, `station` here, or it stores and returns the value we pass as the second argument which is a reference to an instance of `TempStat` with the min, max, sum set to the only measurement value we have for that station and count set to 1 since we've only seen it one time.
The return value from the results `sync.Map` is `any` so we need to assert its type as a pointer to `TempStat`.
The pointers and references are used so we don't pass around the concrete instance of the struct which would be more data and therefore slower.
At the end of the function there is a simple update of min, max, sum and count for the station.
The `if` statements are separate and look a bit weird, it ended up being a bit faster to do it this way and also less duplicate code than the `if..else if..else` version.
And with all that explained, here is the definition of the `ProcessLine` function:

{{< highlight go >}}
// ProcessLine processes a single line and updates temperature stats in the map
func ProcessLine(line string, results *sync.Map) {
	// Locate the index of the delimiter,
	delimiterIndex := strings.Index(line, ";")
	// and split the line according to that.
	station, measurement := line[:delimiterIndex], line[delimiterIndex+1:]
	// To store the measurement, first read it as a float (faster than ParseInt),
	tempFloat, _ := strconv.ParseFloat(measurement, 64)
	// and then since we know it'll be in the [-99.9,99.9] range multiply by 10 and store as int
	temp := int64(tempFloat * 10)

	// Atomic map update using sync.Map
	value, _ := results.LoadOrStore(station, &TempStat{Min: temp, Max: temp, Sum: temp, Count: 1})
	// Get stats for relevant station
	stat := value.(*TempStat)

	// Update station temp stats
	if temp > stat.Max {
		stat.Max = temp
	}
	if temp < stat.Min {
		stat.Min = temp
	}
	stat.Sum += temp
	stat.Count++
}
{{< /highlight >}}

### Round and Print

Grouping the output and the rounding might seem a bit odd but the challenge mentions rounding only with regards to output.
There is no other point in the code where rounding is relevant so I'll explain both of these together.
I decided to not invest too much time in this part so it is fairly idiomatic and can most likely be improved.

The `Round` function just calls out to [`math.Round`](https://pkg.go.dev/math#Round) which looks like it does the thing the challenge asks for.
Being frank, I do not remember why the times 10 and then divide by 10 is in here.
There is a special case for zero implemented, I think my result failed validation otherwise.

{{< highlight go >}}
// Round does roundTowardsPositive
func Round(x float64) float64 {
	rounded := math.Round(x * 10)
	if rounded == -0.0 {
		return 0.0
	}
	return rounded / 10
}
{{< /highlight >}}

The `PrintOutput` function is generally pretty boring outside of the `sync.Map` usage and the int to float conversions.
The original input data has floating point measurements, we converted them to integers for processing speed but now we need to calculate the average and provide min/max/avg as floats.
We pay the cost of calculating the average once per program run instead of once per line processed which is incredibly benficial when the dataset is one billion measurements.
The printing works by getting the station names since that is the unique identifier here.
There doesn't seem to be a better way to do this so a function collects all the station names and stores them in a slice of strings and always returns true to satisfy the type of that argument (`func (m *Map) Range(f func(key, value any) bool)`).
After that, the list of station names is sorted and we construct the output string.
For each station, the integer values are converted to floats and reduced by an order of magnitude to normalize them to the original values and then passed through `Round()`.
Last, we print the result to standard output:

{{< highlight go >}}
// PrintOutput prints the final temperature statistics for each station
func PrintOutput(results *sync.Map) {
	stations := []string{}

	results.Range(func(key, value any) bool {
		stations = append(stations, key.(string))
		return true
	})
	sort.Strings(stations)

	finalResultString := "{"
	for idx, station := range stations {
		stat, _ := results.Load(station)
		tempStats := stat.(*TempStat)

		finalResultString += fmt.Sprintf(
			"%s=%.1f/%.1f/%.1f",
			station,
			Round(float64(tempStats.Min)/10.0),
			Round((float64(tempStats.Sum)/10.0)/float64(tempStats.Count)),
			Round(float64(tempStats.Max)/10.0),
		)

		// Add comma and space everywhere except for the last entry
		if idx != len(stations)-1 {
			finalResultString += ", "
		}
	}
	finalResultString += "}"

	fmt.Println(finalResultString)
}
{{< /highlight >}}

The `if` for not adding a comma to the last entry bothers me and could probably be converted to use [`strings.Replace`](https://pkg.go.dev/strings#Replace), probably something like `strings.Replace(finalResultString, ", }", "}", 1)` but oh well, this is how it is now.

### Bringing it together in `main()`

Alright then, we've seen the individual puzzle pieces so far and connecting them seems somewhat intuitive but the code in `main()` was probably the thing I spent most of my time on.
This is because there are several parameters that can be tweaked here, especially so because of the use of [goroutines (A Tour of Go link)](https://go.dev/tour/concurrency/1).
In the big picture, we're looking to read a file with a billion rows and do a simple calculation as fast as possible.
One of the obvious ways to make this fast is to split up the work.
Easy to say but hard to do. How do we split the work? In how many parts? How big should those parts be? How many worker processes should we have?
Answering all of those took a while, the [Go profiler](https://go.dev/doc/diagnostics#profiling) was a huge help here by pointing out where the bottleneck was.
I believe I have done a decent job at explaining the code in the comments, take a look:

{{< highlight go >}}
func main() {
	// Define amount of worker goroutines
	numWorkers := runtime.NumCPU()

	// Set GOMAXPROCS equal to amount of goroutines
	runtime.GOMAXPROCS(numWorkers)

	// Open the measurements file
	file := OpenMeasurementsFile()
	defer file.Close()

	// Create thread-safe map to store station statistics
	results := &sync.Map{}

	// Create a channel to send lines to workers
	lineChan := make(chan []string, 1000)

	// Set number of goroutines to wait for
	wg.Add(numWorkers)
	// Create goroutines based on predefined amount
	for i := 0; i < numWorkers; i++ {
		go ProcessLineGroup(lineChan, results)
	}

	// Set chunk size
	chunkSize := 64 * 1024
	// Create fixed-size buffer over which to send chunks
	buf := make([]byte, chunkSize)
	// Keep any partial line for later processing
	partialLine := ""

	for {
		// Read file into buffer
		n, _ := file.Read(buf)
		if n > 0 {
			// Split the buffer into lines
			chunk := partialLine + string(buf[:n])
			lines := strings.Split(chunk, "\n")

			// Save the last line if it is incomplete
			partialLine = lines[len(lines)-1]

			// Send lines to channel in batches
			if len(lines) > 0 {
				lineChan <- lines[:len(lines)-1]
			}
		} else {
			break
		}
	}

	// Send any remaining partial line
	if len(partialLine) > 0 {
		lineChan <- []string{partialLine}
	}

	// Close the channel after all lines have been processed
	close(lineChan)

	// Wait for all workers to finish
	wg.Wait()

	// Print the final results
	PrintOutput(results)
}
{{< /highlight >}}

Now that you've seen the code, I have some notes in no particular order.
The channel mechanism allows `main()` to send the lines to `ProcessLineGroup()` runnin in the multiple goroutines which then process the line groups created from a `64 * 1024` chunk of bytes.
The goroutines are spawned by the `go ProcessLineGroup(lineChan, results)` call, prefixing a function call with `go` runs it in a goroutine.
The channel and its buffer size is not pefectly tuned but 1000 seemed to be an okay spot to leave it at.
The partial line workaround appears to be unnecessay, I think it's a leftover.

And that's my solution!
Comparing it with `./calculate_average_baseline.sh > out_expected.txt` shows that they are identical.


### Benchmarks

I did a quick run using [hyperfine](https://github.com/sharkdp/hyperfine), the same tool the original challenge author used.
In order to avoid disk caching skewing the results I used the `--prepare` option to sync the filesystem and drop the disk cache:

{{< highlight shell >}}
cd ~/go/src/ongoing/x/1brc && go build
hyperfine --warmup 0 --prepare 'sync; echo 3 | sudo tee /proc/sys/vm/drop_caches' './1brc ~/gitty/1brc/measurements.txt'

Time (mean ± σ):     42.469 s ±  0.654 s    [User: 118.403 s, System: 8.892 s]
Range (min … max):   41.712 s … 43.710 s    10 runs
{{< /highlight >}}

So I'm at about 42-43 seconds. Not amazing but it's at least under 1 minute.

## How to get started

Looking at READMEs and figuring out scripts takes a couple of minutes so I think a short how to might help lower the barrier to entry.
So here are the setup steps:
- `git clone https://github.com/gunnarmorling/1brc`
- `./mvnw clean verify`
- `./create_measurements.sh 1000000000`
- `./calculate_average_baseline.sh > out_expected.txt`

Now you have the measurements file and the expected output to compare to.
You can save your solution's output to a file (e.g. `my_output.txt`) and use something like `diff --suppress-common-lines out_expected.txt my_output.txt` to see if you got it right.
After you've checked for correctness, it's time to optimize and then re-check that you're producing correct results but faster!
You can use the `hypefine` command I used as well to check for speed.

## Conclusion

My shell history says I started working on this challenge October 2024.
I don't know why almost 2 years later it dawned on me to write a blog post about it but I hope you decide to take it on and have as much fun as I did.
