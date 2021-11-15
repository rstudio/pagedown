
describe("Long tables", () => {
    beforeAll(async () => {
        // TODO encapsulate the file path to make it easier to replicate in other tests
        const cwd = process.cwd();
        //const htmlFile = `file://{ $cwd }/tests/test-output/longtable.html`; // TODO not working
        const htmlFile = 'file://' + cwd + '/tests/test-output/longtable.html';
        await page.goto(htmlFile);
    });

    it("Must page break", async () => {
         const pageCount = await page.$$eval(
            '.pagedjs_page', 
            (el) => el.length);
        
        expect(pageCount).toEqual(8);
    })
});
