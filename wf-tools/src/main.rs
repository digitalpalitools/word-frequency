use colored::*;
use csv::ReaderBuilder;
use linked_hash_set::*;
use std::collections::HashMap;
use std::io::Write;
use std::io::{self, BufRead};
use std::path::Path;
use std::{env, fs::File};

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        pln(format!(
            "Usage: wf-tools <wf_base_path> <node_list>\n... Received args {:?}",
            args
        )
        .yellow());
        return;
    }

    let wf_base_path = &args[1];
    let file_path = &args[2];

    pln(format!("Executing with: {} {}", wf_base_path, file_path).bright_white());

    let res = read_lines(file_path);
    if res.is_err() {
        pln(format!("Error reading {}", file_path).red());
        return;
    }

    let lines = res
        .unwrap()
        .filter_map(get_line)
        .filter_map(move |l| get_wf_path_from_line(wf_base_path, &l));

    let lines = lines
        .fold(LinkedHashSet::new(), |mut acc, e| {
            if acc.contains(&e) {
                pln(format!("Ignoring duplicate file {}", &e).yellow());
            }

            acc.insert(e);
            acc
        });

    let wf_map = lines
        .iter()
        .map(|x| get_records_from_csv_file(x))
        .fold(HashMap::new(), merge_records_into_hash_map);
    pln(format!("Total records {:#?}", wf_map.len()).green());

    let out_file = File::create(file_path.to_string() + ".wf.csv");
    if out_file.is_err() {
        pln(format!("Error: Unable to read line due to error {:#?}", out_file).red());
        return;
    }

    let out_file = out_file.unwrap();
    let ret = writeln!(&out_file, "Pāli,Frequency,Length");
    if ret.is_err() {
        pln(format!("Error: Unable to write line {:#?}", ret).red());
        return;
    }

    let mut wf_list: Vec<_> = wf_map.iter().collect();
    wf_list.sort_by(|&x, &y| y.1.cmp(x.1));
    wf_list.iter().for_each(|(word, freq)| {
        let length = corelib::string_length(word);
        let ret = writeln!(&out_file, "{},{},{}", word, freq, length);
        if ret.is_err() {
            pln(format!("Error: Unable to write line {:#?}", ret).red());
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

// TODO: How to return HasMap<&str, usize> instead of HasMap<String, usize>?
// TODO: How do I return Iterator<Item = (String, usize)> instead of creating a vector?
fn get_records_from_csv_file(wf_file_path: &str) -> Vec<(String, usize)> {
    p(format!("Processing {:#?}", wf_file_path).green());

    let wf_file = File::open(&wf_file_path);
    if wf_file.is_err() {
        pln(format!(
            "Error: Unable to convert file {:#?} for reading!",
            &wf_file_path
        )
        .red());
        let empty: Vec<(String, usize)> = vec![];
        return empty;
    }

    let mut reader = ReaderBuilder::new()
        .has_headers(false)
        .from_reader(wf_file.unwrap());
    let recs = reader
        .records()
        .filter_map(|r| match r {
            Err(e) => {
                pln(format!("Error: Unable to read record {:#?}!", e).red());
                None
            }
            Ok(rec) => Some(rec),
        })
        .filter_map(|rec| {
            if rec.len() != 2 {
                pln(format!("Error: Expecting 2 records, instead found {:#?}!", rec).red());
                return None;
            }

            match rec[1].parse::<usize>() {
                Err(e) => {
                    pln(format!(
                        "Error: Unable get string from record {}. err = {:#?}!",
                        &rec[1], e
                    )
                    .red());
                    None
                }
                Ok(n) => Some((rec[0].to_string(), n)),
            }
        });

    let recs: Vec<_> = recs.collect();
    pln(format!("... [{} records]", recs.len()).green());
    recs
}

fn get_line(l: Result<String, io::Error>) -> Option<String> {
    if l.is_err() {
        pln(format!("Error: Unable to read line due to error {:#?}", l).red());
        return None;
    }

    Some(l.unwrap())
}

fn get_wf_path_from_line(wf_base_path: &str, l: &str) -> Option<String> {
    let wf_file = l.split(",").nth(0);
    if wf_file.is_none() {
        pln(format!("Ignoring empty line! '{}'", l).yellow());
        return None;
    }

    let wf_file = Path::new(wf_base_path).join(format!("{}.wf.csv", wf_file.unwrap()));
    if !wf_file.exists() {
        pln(format!("Ignoring {} as path {:#?} does not exist!", l, wf_file).yellow());
        return None;
    }

    match wf_file.to_str() {
        None => {
            pln(format!("Error: Unable to convert path to string {:#?}!", wf_file).red());
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

fn p(str: ColoredString) {
    print!("{}", str)
}

fn pln(str: ColoredString) {
    println!("{}", str)
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
