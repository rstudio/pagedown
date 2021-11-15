const exec = require('child_process').execSync;

describe("Long tables", () => {
    // TODO encapsulate the file path to make it easier to replicate in other tests
    const cwd = process.cwd();
    const file = 'longtable'
    const rmdFile = cwd + '/tests/test-output/' + file + '.Rmd';
    const htmlFile = cwd + '/tests/test-output/' + file + '.html';
    const htmlFileUri = 'file://' + cwd + '/tests/test-output/' + file + '.html';
    
    beforeAll(async () => {
        exec('Rscript -e "rmarkdown::render(\'' + rmdFile + '\')"');
        await page.goto(htmlFileUri, { waitUntil: "networkidle2" });
    });
    
    afterAll(() => {
        exec('rm \'' + htmlFile + '\'');
    });
    

    it("Must page break", async () => {
         const pageCount = await page.$$eval(
            'div.pagedjs_page', 
            (el) => el.length);
        
        expect(pageCount).toEqual(8);
    });

    it("Must break table", async () => {
        const tableCount = await page.$$eval(
           'table', 
           (el) => el.length);
       
       expect(tableCount).toEqual(6);
   });

    it("Must page repeat thead", async () => {
        const theadCount = await page.$$eval(
           'thead', 
           (el) => el.length);
       
       expect(theadCount).toEqual(6);
   });
});
