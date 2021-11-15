
describe("Long tables", () => {
    beforeAll(async () => {
        // TODO encapsulate the file path to make it easier to replicate in other tests
        const cwd = process.cwd();
        //const htmlFile = `file://{ $cwd }/tests/test-output/longtable.html`; // TODO not working
        const htmlFile = 'file://' + cwd + '/tests/test-output/longtable.html';
        await page.goto(htmlFile, { waitUntil: "networkidle2" });
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
