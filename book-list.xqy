xquery version "1.0-ml";

declare option xdmp:output "method = html";

declare function local:sanitizeInput($chars as xs:string?) {
    fn:replace($chars,"[\]\[<>{}\\();%\+]","")
};

declare function local:bookListQuery(
    $searchType as xs:string,
    $searchInput as xs:string
) {
    let $searchQuery :=
            cts:search(/book,
                if ($searchType eq "All") then(())
                else(
                    cts:and-query((
                    cts:directory-query('/bookstore/','infinity'),
                        cts:word-query($searchInput),

                        if ($searchType eq "Title") then (
                            cts:element-word-query(
                                xs:QName("title"), $searchInput)
                        )
                        else if ($searchType eq "Author") then (
                            cts:element-word-query(
                                xs:QName("author"), $searchInput)
                        )
                        else if ($searchType eq "Year") then (
                            cts:element-word-query(
                                xs:QName("year"), $searchInput)
                        )
                        else if ($searchType eq "Price") then (
                            cts:element-word-query(
                                xs:QName("price"), $searchInput)
                        )
                        else if ($searchType eq "Category") then (
                            cts:element-attribute-word-query(
                                xs:QName("book"), xs:QName("category"), $searchInput)
                        )
                        else()
                    ))
                )
            )
    return $searchQuery
};

declare variable $bookList :=
    if (xdmp:get-request-method() eq "GET") then (
        let $searchType := xdmp:get-request-field("searchType")
        let $searchInput := local:sanitizeInput(xdmp:get-request-field("Input"))
        return
            local:bookListQuery($searchType, $searchInput)
    ) else ();

declare function local:editBook($id) {
    let $redirectUri := ("update.xqy?id=" || $id)
    return
        xdmp:redirect-response($redirectUri)
};

(: build the html :)
xdmp:set-response-content-type("text/html"),
'<!DOCTYPE html>',
<html>
    <head>
        <link rel="stylesheet" type="text/css" href="/css/style.css"/>
        <title>Book List</title>
    </head>
    <body>
        <div class="nav-container">
            <a href="book-list.xqy" class="nav-item">Find a Book</a>
            <a href="add-book.xqy" class="nav-item">Add books to Library</a>
            <a href="content-admin.xqy" class="nav-item">Books Admin Page</a>
        </div>
        <h1 class="mainTitle">Find a Book</h1>

        <form method="GET" action="book-list.xqy">
            <div class="search-container">
                <h3>Keyword Search:</h3>
                <select name="searchType" class="search-item">
                    {
                    for $field in ('All', 'Title', 'Author', 'Year', 'Price', 'Category')
                    return
                        <option value="{$field}">{$field}</option>
                    }
                </select>
                <div class="search-item">
                    <input name="Input" type="text"/>
                    <input type="submit" value="Search"/>
                </div>
            </div>
        </form>
        {
        if (fn:exists($bookList)) then (
            <h3>Search Results</h3>,
            <div class="table-container">
                <div class="table-head-container">
                    <div class="table-head-title"><strong>Title</strong></div>
                    <div class="table-head"><strong>Author</strong></div>
                    <div class="table-head"><strong>Year</strong></div>
                    <div class="table-head"><strong>Price</strong></div>
                    <div class="table-head"><strong>Category</strong></div>
                    <div class="table-head"><strong></strong></div>
                </div>
                {
                for $book in $bookList
                order by $book/title
                return
                    <div class="table-data-container">
                        <div class="table-data-title">{data($book/title)}</div>
                        <div class="table-data">{data($book/author)}</div>
                        <div class="table-data">{data($book/year)}</div>
                        <div class="table-data">{data($book/price)}</div>
                        <div class="table-data">{$book/data(@category)}</div>
                        <div class="table-data">
                            <button class="edit-button" onclick="location.href='/update.xqy?id={$book/data(@id)}'">edit</button>
                        </div>
                    </div>
                }
            </div>
        ) else (
            <h3>No Search Results Found</h3>
        )
        }

    </body>
</html>