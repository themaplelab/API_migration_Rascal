## Loomizer

![LOOMIZER-6-13-2024 (1)](https://github.com/themaplelab/Loomizer/assets/56334497/1fdb5df6-950f-4edb-a57f-ed1539840daf)
A set of Rascal transformations for helping developers to migrate traditional java threads to Loom API virtual threads.

### Requirements

   * Python 3
   * Java 19+

### Build and run

   * Clone this repository (`git clone git@github.com:themaplelab/Loomizer.git`)
   * Change to the Loomizer folder (`cd Loomizer`) 
   * Download the Rascal shell (`wget https://update.rascal-mpl.org/console/rascal-shell-stable.jar`)
   * Change the root directory path (Sometimes, if your java application does not have "src" folder, you need to remove "and os.path.basename(filename) == "src"" in line 24 in `driver.py` and change the recursive property in glob() function accordingly)
   * Execute the `driver.py` script:

```shell
$ python3 driver.py 
```
