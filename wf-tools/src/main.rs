use std::collections::{HashMap, HashSet};
use std::io::Write;
use std::io::{self, BufRead};
use std::path::Path;
use std::{env, fs::File};

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        println!(
            "Usage: wf-tools <wf_base_path> <node_list>\n ... Received args {:?}",
            args
        );
        return;
    }

    let wf_base_path = &args[1];
    let file_path = &args[2];

    println!("Executing with: {} {}", wf_base_path, file_path);

    let res = read_lines(file_path);
    if res.is_err() {
        println!("Error reading {}", file_path);
        return;
    }

    let lines = res
        .unwrap()
        .filter_map(get_line)
        .fold(HashSet::new(), |mut acc, e| {
            acc.insert(e);
            acc
        });

    let wf_map = lines
        .iter()
        .filter_map(move |l| get_wf_path_from_line(wf_base_path, l))
        .map(get_records_from_csv_file)
        .fold(HashMap::new(), merge_records_into_hash_map);

    let out_file = File::create(file_path.to_string() + ".wf.csv");
    if out_file.is_err() {
        println!("Error: Unable to read line due to error {:#?}", out_file);
        return;
    }

    let out_file = out_file.unwrap();
    let ret = writeln!(&out_file, "Pāli,Frequency,Length");
    if ret.is_err() {
        println!("Error: Unable to write line {:#?}", ret);
        return;
    }

    let mut wf_list: Vec<_> = wf_map.iter().collect();
    wf_list.sort_by(|&x, &y| y.1.cmp(x.1));
    wf_list.iter().for_each(|(word, freq)| {
        let length = corelib::string_length(word);
        let ret = writeln!(&out_file, "{},{},{}", word, freq, length);
        if ret.is_err() {
            println!("Error: Unable to write line {:#?}", ret);
        }
    });
}

fn merge_records_into_hash_map(
    acc: HashMap<String, usize>,
    e: Vec<(String, usize)>,
) -> HashMap<String, usize> {
    e.iter().fold(acc, |mut acc, e| {
        if acc.contains_key(&e.0) {
            acc.insert(e.0.clone(), acc[&e.0] + e.1);
        } else {
            acc.insert(e.0.clone(), e.1);
        }

        acc
    })
}

// TODO: How to make file &str instead of String?
// TODO: How to return HasMap<&str, usize> instead of HasMap<String, usize>?
// TODO: How do I return Iterator<Item = (String, usize)> instead of creating a vector?
fn get_records_from_csv_file(wf_file_path: String) -> Vec<(String, usize)> {
    let wf_file = File::open(&wf_file_path);
    if wf_file.is_err() {
        println!(
            "Error: Unable to convert file {:#?} for reading!",
            &wf_file_path
        );
        let empty: Vec<(String, usize)> = vec![];
        return empty;
    }

    let mut reader = csv::Reader::from_reader(wf_file.unwrap());
    let recs = reader
        .records()
        .filter_map(|r| match r {
            Err(e) => {
                println!("Error: Unable to read record {:#?}!", e);
                None
            }
            Ok(rec) => Some(rec),
        })
        .filter_map(|rec| {
            if rec.len() != 2 {
                println!("Error: Expecting 2 records, instead found {:#?}!", rec);
                return None;
            }

            match rec[1].parse::<usize>() {
                Err(e) => {
                    println!(
                        "Error: Unable get string from record {}. err = {:#?}!",
                        &rec[1], e
                    );
                    None
                }
                Ok(n) => Some((rec[0].to_string(), n)),
            }
        });

    recs.collect()
}

fn get_line(l: Result<String, io::Error>) -> Option<String> {
    if l.is_err() {
        println!("Error: Unable to read line due to error {:#?}", l);
        return None;
    }

    Some(l.unwrap())
}

fn get_wf_path_from_line(wf_base_path: &str, l: &String) -> Option<String> {
    let wf_file = Path::new(wf_base_path).join(format!("{}.wf.csv", l));
    if !wf_file.exists() {
        println!("Error: Path {:#?} does not exist!", wf_file);
        return None;
    }

    match wf_file.to_str() {
        None => {
            println!("Error: Unable to convert path to string {:#?}!", wf_file);
            None
        }
        Some(wf_file) => Some(wf_file.to_string()),
    }
}

fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where
    P: AsRef<Path>,
{
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_merge_records_into_hash_map_no_records() {
        let mut hm = HashMap::new();
        hm.insert("a".to_string(), 10usize);

        let hm = merge_records_into_hash_map(hm, vec![]);

        assert_eq!(hm.len(), 1);
        assert_eq!(hm["a"], 10);
    }

    #[test]
    fn test_merge_records_into_hash_map_new_record() {
        let mut hm = HashMap::new();
        hm.insert("a".to_string(), 10usize);

        let hm = merge_records_into_hash_map(hm, vec![("b".to_string(), 11usize)]);

        assert_eq!(hm.len(), 2);
        assert_eq!(hm["a"], 10);
        assert_eq!(hm["b"], 11);
    }

    #[test]
    fn test_merge_records_into_hash_map_overlapping_record() {
        let mut hm = HashMap::new();
        hm.insert("a".to_string(), 10usize);
        hm.insert("b".to_string(), 11usize);

        let hm = merge_records_into_hash_map(hm, vec![("a".to_string(), 9usize)]);

        assert_eq!(hm.len(), 2);
        assert_eq!(hm["a"], 19);
        assert_eq!(hm["b"], 11);
    }
}
